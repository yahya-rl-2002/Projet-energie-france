# Fonctions pures : aucune collecte, écriture ou exécution lors de source().
verifier_grille <- function(df) {
  if (!all(c("Date", "Consommation") %in% names(df)) || nrow(df) < 2L)
    stop("Une série Date/Consommation d'au moins deux heures est requise.")
  if (anyNA(df$Date) || any(diff(as.numeric(df$Date)) != 3600))
    stop("Les dates doivent être uniques, ordonnées et espacées de 3600 secondes.")
  invisible(TRUE)
}

# Les exports historiques ne distinguent pas les deux occurrences de 02 h
# en automne. On laisse ces instants manquants plutôt que d'inventer un ordre.
parser_dates_locales <- function(labels, tz = "Europe/Paris") {
  labels <- ifelse(nchar(labels) == 10L, paste(labels, "00:00:00"), labels)
  if (anyNA(labels) || any(!grepl("^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:00$", labels)))
    stop("Dates locales attendues au format YYYY-MM-DD HH:MM:00.")
  naive <- as.POSIXct(labels, format = "%Y-%m-%d %H:%M:%S", tz = "UTC")
  if (anyNA(naive) || any(as.numeric(naive) %% 900 != 0))
    stop("Dates invalides ou non alignées sur un quart d'heure.")
  grid <- seq(min(naive) - 86400, max(naive) + 86400, by = 900)
  wall <- format(grid, tz = tz, format = "%Y-%m-%d %H:%M:%S")
  ambiguous <- duplicated(wall) | duplicated(wall, fromLast = TRUE)
  ambiguous_labels <- unique(wall[ambiguous])
  idx <- match(labels, wall[!ambiguous])
  list(Date = grid[!ambiguous][idx],
       ambigu = labels %in% ambiguous_labels,
       inexistant = is.na(idx) & !(labels %in% ambiguous_labels))
}

preparer_horaire <- function(brut, tz = "Europe/Paris") {
  d <- data.table::as.data.table(brut)
  if (!all(c("Date", "Consommation") %in% names(d))) stop("Colonnes manquantes.")
  n_brut <- nrow(d)
  labels <- as.character(d$Date)
  if ("Heures" %in% names(d)) labels <- paste(labels, d$Heures)
  # Les fichiers RTE combinés peuvent contenir des lignes de pied de page.
  valide <- is.finite(d$Consommation) & d$Consommation > 0
  d <- data.table::data.table(Label = labels[valide], Consommation = d$Consommation[valide])
  if (nrow(d) < 4L) stop("Données de consommation insuffisantes.")
  parsed <- parser_dates_locales(d$Label, tz)
  d[, Date := parsed$Date]
  n_ambigu <- sum(parsed$ambigu)
  n_inexistant <- sum(parsed$inexistant)
  d <- d[!is.na(Date)]
  conflits <- d[, .(N = data.table::uniqueN(Consommation)), by = Date][N > 1L]
  if (nrow(conflits)) stop("Consommations contradictoires au même instant : résoudre les sources.")
  n_doublons <- nrow(d) - data.table::uniqueN(d$Date)
  d <- unique(d, by = "Date")
  data.table::setorder(d, Date)
  d[, Jour := substr(Label, 1, 10)]
  # Cadence observée par journée, sans extrapoler une valeur au travers d'un trou.
  cadences <- d[, .(Pas = {
    delta <- diff(as.numeric(Date))
    delta <- delta[delta %in% c(900, 1800)]
    if (length(delta)) min(delta) else NA_real_
  }), by = Jour]
  d <- merge(d, cadences, by = "Jour", all.x = TRUE, sort = FALSE)
  d <- d[!is.na(Pas)]
  if (!nrow(d)) stop("Impossible de déterminer la cadence des observations.")
  if (any((as.numeric(d$Date) %% 3600) + d$Pas > 3600))
    stop("Intervalle de mesure chevauchant une heure : cadence incohérente.")
  d[, Heure := floor(as.numeric(Date) / 3600) * 3600]
  h <- d[, .(Couverture_secondes = sum(Pas),
             Consommation = sum(Consommation * Pas) / sum(Pas)), by = Heure]
  if (any(h$Couverture_secondes > 3600)) stop("Mesures temporelles chevauchantes.")
  h[Couverture_secondes != 3600, Consommation := NA_real_]
  grid <- data.table::data.table(Heure = seq(min(h$Heure), max(h$Heure), by = 3600))
  h <- merge(grid, h, by = "Heure", all.x = TRUE, sort = TRUE)
  h[is.na(Couverture_secondes), Couverture_secondes := 0]
  h[, Date := as.POSIXct(Heure, origin = "1970-01-01", tz = "UTC")]
  h[, Date_locale := format(Date, tz = tz, format = "%Y-%m-%d %H:%M:%S %z")]
  h <- h[, .(Date, Date_locale, Consommation, Couverture_secondes)]
  verifier_grille(h)
  list(donnees = h, qualite = list(
    lignes_source = n_brut, lignes_sans_consommation_positive = sum(!valide),
    doublons_identiques_retires = n_doublons,
    lignes_heure_ambigue_exclues = n_ambigu,
    lignes_heure_inexistante_exclues = n_inexistant,
    heures_grille = nrow(h), heures_completes = sum(!is.na(h$Consommation)),
    heures_manquantes_ou_incompletes = sum(is.na(h$Consommation)),
    fuseau_source = tz, fuseau_grille = "UTC",
    debut_utc = format(min(h$Date), tz = "UTC", usetz = TRUE),
    fin_utc = format(max(h$Date), tz = "UTC", usetz = TRUE)))
}

# Imputation uniquement dans l'entraînement et exclusivement à partir du passé.
imputer_passe <- function(y, max_trou = 6L) {
  if (any(is.infinite(y))) stop("Valeur infinie.")
  trous <- rle(is.na(y))
  if (any(trous$values & trous$lengths > max_trou)) stop("Trou d'entraînement trop long.")
  if (is.na(y[1])) stop("La fenêtre doit commencer par une observation réelle.")
  for (i in which(is.na(y))) {
    retard <- if (i > 168L) 168L else if (i > 24L) 24L else 1L
    y[i] <- y[i - retard]
  }
  y
}

metriques_horaires <- function(obs, pred, train, saison = 24L) {
  if (length(obs) != length(pred) || !length(obs) ||
      any(!is.finite(c(obs, pred, train)))) stop("Vecteurs de métriques invalides.")
  err <- obs - pred
  denom <- if (length(train) > saison) mean(abs(diff(train, lag = saison))) else NA_real_
  sst <- sum((obs - mean(obs))^2)
  data.frame(N = length(obs), RMSE = sqrt(mean(err^2)), MAE = mean(abs(err)),
    MAPE = if (any(obs == 0)) NA_real_ else 100 * mean(abs(err / obs)),
    R_squared = if (sst > 0 && length(obs) > 1L) 1 - sum(err^2) / sst else NA_real_,
    MASE = if (is.finite(denom) && denom > 0) mean(abs(err)) / denom else NA_real_)
}

prevoir_modele <- function(train, modele, h) {
  if (any(!is.finite(train)) || length(train) < 168L) stop("Entraînement invalide.")
  x <- ts(train, frequency = 24)
  if (modele == "Persistance") return(list(mean = rep(tail(train, 1), h)))
  if (modele == "Naif_24h") return(list(mean = rep(tail(train, 24), length.out = h)))
  if (modele == "Naif_168h") return(list(mean = rep(tail(train, 168), length.out = h)))
  fit <- switch(modele,
    ETS = forecast::ets(x),
    ARIMA = forecast::auto.arima(x, seasonal = TRUE, stepwise = TRUE,
      approximation = TRUE, max.p = 2, max.q = 2, max.P = 1, max.Q = 1),
    stop("Modèle inconnu : ", modele))
  f <- forecast::forecast(fit, h = h, level = c(80, 95))
  list(mean = as.numeric(f$mean), lower = f$lower, upper = f$upper,
       specification = if (modele == "ETS") fit$method else paste(forecast::arimaorder(fit), collapse = ","))
}

fenetre_origine <- function(df, origine, train_heures, h) {
  verifier_grille(df)
  idx <- match(as.numeric(origine), as.numeric(df$Date))
  if (is.na(idx) || idx < train_heures || idx + h > nrow(df)) stop("Origine hors bornes.")
  train_idx <- seq.int(idx - train_heures + 1L, idx)
  test_idx <- seq.int(idx + 1L, idx + h)
  train_brut <- df$Consommation[train_idx]
  test <- df$Consommation[test_idx]
  # Les cibles ne sont jamais imputées : mêmes dates et mêmes erreurs pour tous.
  if (anyNA(test)) stop("Cibles de test manquantes : origine exclue pour tous les modèles.")
  list(train = imputer_passe(train_brut), test = test,
       dates = df$Date[test_idx], n_imputees = sum(is.na(train_brut)),
       train_debut = df$Date[min(train_idx)], train_fin = df$Date[max(train_idx)])
}
