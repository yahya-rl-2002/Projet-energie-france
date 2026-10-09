# Rscript tests/test_pipeline_horaire.R
source("00_Utilitaires/series_horaires.R")
source("04_Validation/validation_horaire.R")
echoue <- function(expr) inherits(tryCatch({force(expr); NULL}, error = identity), "error")

b <- data.frame(Date = c("2024-01-01 00:00:00", "2024-01-01 00:30:00",
  "2024-01-02 00:00:00", "2024-01-02 00:15:00", "2024-01-02 00:30:00", "2024-01-02 00:45:00"),
  Consommation = c(100, 200, 100, 200, 300, 400))
r <- preparer_horaire(rbind(b, b[1, ]))
stopifnot(r$qualite$doublons_identiques_retires == 1,
  r$donnees$Consommation[1] == 150, tail(r$donnees$Consommation, 1) == 250,
  all(diff(as.numeric(r$donnees$Date)) == 3600), sum(is.na(r$donnees$Consommation)) == 23)
stopifnot(echoue(preparer_horaire(rbind(b, transform(b[1, ], Consommation = 999)))))
partial <- preparer_horaire(b[-6, ])
stopifnot(is.na(tail(partial$donnees$Consommation, 1)))

p <- parser_dates_locales(c("2024-10-27 01:30:00", "2024-10-27 02:00:00",
  "2024-10-27 02:30:00", "2024-10-27 03:00:00", "2024-03-31 02:00:00"))
stopifnot(identical(p$ambigu, c(FALSE, TRUE, TRUE, FALSE, FALSE)),
  p$inexistant[5], all(is.na(p$Date[c(2, 3, 5)])))

m <- metriques_horaires(c(10, 12), c(9, 10), 1:200)
stopifnot(abs(m$MASE - 1.5 / 24) < 1e-12,
  is.na(metriques_horaires(10, 9, 1:200)$R_squared),
  echoue(metriques_horaires(1:3, 1:2, 1:200)))

df <- data.frame(Date = seq(as.POSIXct("2024-01-01", tz = "UTC"), by = 3600, length.out = 1000),
                 Consommation = 1000 + seq_len(1000))
w <- fenetre_origine(df, df$Date[800], 336, 168)
stopifnot(w$train_fin < min(w$dates), length(w$train) == 336)
changed <- df; changed$Consommation[801:1000] <- 99999
stopifnot(identical(w$train, fenetre_origine(changed, df$Date[800], 336, 168)$train))
changed$Consommation[805] <- NA
stopifnot(echoue(fenetre_origine(changed, df$Date[800], 336, 168)))
stopifnot(echoue(imputer_passe(c(1, rep(NA_real_, 7), 2))))

for (nom in c("Persistance", "Naif_24h", "Naif_168h"))
  stopifnot(length(prevoir_modele(1:336, nom, 168)$mean) == 168)
stopifnot(identical(prevoir_modele(1:336, "Naif_24h", 25)$mean, c(313:336, 313L)))
scores <- evaluer_origines(df, df$Date[c(600, 800)], c("Persistance", "Naif_24h", "Naif_168h", "ETS", "ARIMA"),
                         train_heures = 336)
stopifnot(all(scores$metriques$N_origines == 2),
  all(scores$predictions$Date > scores$predictions$Origine),
  all(scores$metriques[Horizon == 24]$N == 48))
stopifnot(all(is.finite(scores$predictions[Modele == "ETS"]$Lower95)),
          all(is.na(scores$predictions[Modele == "Persistance"]$Lower95)))
message("Tests horaires : OK")
