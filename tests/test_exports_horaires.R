# Intégration : pipeline complet sur données synthétiques, sans sources privées.
source("EXECUTER_TOUT.R")
racine_test <- tempfile("energie-test-")
dir.create(racine_test)
fichiers <- c("EXECUTER_TOUT.R", "00_Utilitaires/series_horaires.R",
              "01_Donnees/preparer_donnees_horaires.R", "04_Validation/validation_horaire.R")
for (p in fichiers) {
  dir.create(dirname(file.path(racine_test, p)), recursive = TRUE, showWarnings = FALSE)
  stopifnot(file.copy(p, file.path(racine_test, p)))
}
dir.create(file.path(racine_test, "data"))
dates <- seq(as.POSIXct("2023-12-01", tz = "UTC"), as.POSIXct("2025-01-03", tz = "UTC"), by = 1800)
raw <- data.frame(Date = format(dates, tz = "Europe/Paris", format = "%Y-%m-%d %H:%M:%S"),
  Consommation = 50000 + 5000 * sin(seq_along(dates) * 2 * pi / 48))
data.table::fwrite(raw, file.path(racine_test, "data/dataset_complet.csv"))
avant <- tools::md5sum(file.path(racine_test, "data/dataset_complet.csv"))
jsonlite::write_json(list(annee_validation = 2024L, annee_test = 2025L,
  train_heures = 336L, horizons = c(1L, 24L), horizon_selection = 24L,
  modeles = "Naif_24h"), file.path(racine_test, "config_horaire.json"), auto_unbox = TRUE)
r <- executer_pipeline_horaire(racine_test)
stopifnot(r$selection == "Naif_24h", all(r$test$metriques$N_origines == 1),
  identical(avant, tools::md5sum(file.path(racine_test, "data/dataset_complet.csv"))),
  file.exists(file.path(racine_test, "docs/resultats_corriges/RAPPORT.md")))
prev <- data.table::fread(file.path(racine_test, "docs/resultats_corriges/previsions_168h.csv"))
stopifnot(nrow(prev) == 24, all(diff(as.numeric(prev$Date)) == 3600))
unlink(racine_test, recursive = TRUE)
message("Tests des exports : OK")
