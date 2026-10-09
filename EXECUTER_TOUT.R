# Rscript EXECUTER_TOUT.R, depuis la racine du dépôt.
# Aucun téléchargement ni écrasement du dataset initial.
executer_pipeline_horaire <- function(racine = ".") {
  racine <- normalizePath(racine, mustWork = TRUE)
  for (p in c("data.table", "forecast", "jsonlite")) {
    if (!requireNamespace(p, quietly = TRUE)) stop("Installer le package : ", p)
  }
  for (p in c("00_Utilitaires/series_horaires.R", "01_Donnees/preparer_donnees_horaires.R",
              "04_Validation/validation_horaire.R")) source(file.path(racine, p), local = TRUE)
  config <- jsonlite::read_json(file.path(racine, "config_horaire.json"), simplifyVector = TRUE)
  docs <- file.path(racine, "docs/resultats_corriges")
  out <- file.path(racine, "data/resultats_corriges")
  dir.create(docs, recursive = TRUE, showWarnings = FALSE)
  dir.create(out, recursive = TRUE, showWarnings = FALSE)
  preparation <- executer_preparation_horaire(racine)
  df <- preparation$donnees
  jsonlite::write_json(preparation$qualite, file.path(docs, "qualite_donnees.json"),
                       pretty = TRUE, auto_unbox = TRUE)
  resultats <- executer_validation_horaire(df, config)
  for (phase in c("validation", "test")) {
    r <- resultats[[phase]]
    data.table::fwrite(r$metriques, file.path(docs, paste0("metriques_", phase, ".csv")), na = "NA")
    data.table::fwrite(r$details, file.path(docs, paste0("metriques_par_origine_", phase, ".csv")), na = "NA")
    data.table::fwrite(r$exclusions, file.path(docs, paste0("origines_exclues_", phase, ".csv")), na = "NA")
    data.table::fwrite(r$predictions, file.path(out, paste0("predictions_", phase, ".csv")), na = "NA")
  }
  dernier <- max(which(!is.na(df$Consommation)))
  if (dernier < config$train_heures) stop("Historique final insuffisant.")
  train <- imputer_passe(df$Consommation[seq.int(dernier - config$train_heures + 1L, dernier)])
  futur <- prevoir_modele(train, resultats$selection, max(config$horizons))
  prev <- data.table::data.table(
    Date = df$Date[dernier] + seq_along(futur$mean) * 3600,
    Modele = resultats$selection, Prediction_MW = futur$mean)
  data.table::fwrite(prev, file.path(docs, "previsions_168h.csv"))
  manifesto <- list(
    genere_utc = format(Sys.time(), tz = "UTC", usetz = TRUE), config = config,
    selection_validation = resultats$selection,
    date_origine_previsions_utc = format(df$Date[dernier], tz = "UTC", usetz = TRUE),
    type_scores = "Erreurs cumulées des pas 1 à H, agrégées sur toutes les origines admissibles",
    donnees = preparation$qualite,
    code_md5 = as.list(tools::md5sum(file.path(racine, c("EXECUTER_TOUT.R",
      "config_horaire.json", "00_Utilitaires/series_horaires.R",
      "01_Donnees/preparer_donnees_horaires.R", "04_Validation/validation_horaire.R")))))
  names(manifesto$code_md5) <- basename(names(manifesto$code_md5))
  jsonlite::write_json(manifesto, file.path(docs, "protocole.json"), pretty = TRUE, auto_unbox = TRUE)
  capture.output(sessionInfo(), file = file.path(docs, "sessionInfo.txt"))
  table_md <- function(x) {
    x <- as.data.frame(x)
    for (nm in names(x)) if (is.numeric(x[[nm]])) x[[nm]] <- format(round(x[[nm]], 3), trim = TRUE)
    c(paste0("| ", paste(names(x), collapse = " | "), " |"),
      paste0("| ", paste(rep("---", ncol(x)), collapse = " | "), " |"),
      apply(x, 1, function(row) paste0("| ", paste(row, collapse = " | "), " |")))
  }
  rapport <- c("# Résultats du pipeline horaire corrigé", "",
    "Ces scores remplacent le classement initial. Ils ne sont pas directement comparables aux anciennes métriques : données, dates et horizons ont été corrigés.", "",
    sprintf("Données : %d heures UTC, dont %d complètes. Les heures absentes restent NA dans le dataset.",
      nrow(df), sum(!is.na(df$Consommation))), "",
    "## Protocole", "",
    sprintf("Validation : %d ; test final : %d. Fenêtre d'entraînement glissante : %d heures (%d jours).",
      config$annee_validation, config$annee_test, config$train_heures, config$train_heures / 24),
    "Une origine par mois, avant le 1er à 00 h UTC ; prévision des 168 heures suivantes. Les scores à H portent sur les pas 1 à H, pas uniquement le pas H. Les références de 24/168 h utilisent des heures écoulées UTC, pas toujours la même heure civile autour des changements d'heure.", "",
    "Les cibles ne sont jamais imputées. Une origine avec une cible manquante est exclue pour tous les modèles et consignée. Les petits trous d'entraînement (maximum 6 heures consécutives) sont remplis uniquement à partir du passé. Les modèles sont réentraînés à chaque origine ; leurs réglages et la sélection ne dépendent pas des scores de test.", "",
    paste0("Modèle retenu exclusivement sur la RMSE à 24 h de validation : **", resultats$selection, "**."), "",
    "## Validation", "",
    table_md(resultats$validation$metriques[, .(Modele, Horizon, N_origines, RMSE, MAE, MAPE, R_squared, MASE)]), "",
    "## Test final", "",
    table_md(resultats$test$metriques[, .(Modele, Horizon, N_origines, RMSE, MAE, MAPE, R_squared, MASE)]), "",
    "## Limites", "",
    "- Évaluation rétrospective sur un instantané, sans garantie que les versions consolidées étaient disponibles à chaque origine historique.",
    "- Seulement une semaine par mois est évaluée ; ce résultat ne couvre pas tous les jours ni tous les événements extrêmes.",
    "- Les horaires sans décalage UTC sont interprétés en Europe/Paris. Les heures civiles ambiguës ou inexistantes sont exclues et les trous conservés ; des sources avec décalage UTC permettraient de les résoudre.",
    "- Chaque mesure représente son intervalle de 15 ou 30 minutes, selon la cadence observée du jour. La moyenne horaire est pondérée par cette durée et exige 60 minutes de couverture.",
    "- Aucun effet causal de météo, de calendrier ou de PIB n'est revendiqué ; les cinq modèles sont univariés.",
    "- ETS/ARIMA : intervalles nominaux évalués en couverture et largeur dans les CSV, sans calibration supplémentaire. Pas d'intervalles inventés pour les références naïves.",
    paste0("- Les prévisions exportées partent de ", manifesto$date_origine_previsions_utc,
           ", dernière heure complète du fichier ; ce ne sont pas des prévisions pour aujourd'hui."), "",
    "## Reproduction", "", "`Rscript EXECUTER_TOUT.R` depuis la racine, avec les mêmes sources (empreintes dans protocole.json).",
    "Les métriques par origine, exclusions, configuration et versions R/packages sont jointes. Les données volumineuses et prédictions détaillées restent locales.")
  writeLines(rapport, file.path(docs, "RAPPORT.md"))
  message("Terminé. Rapport : ", file.path(docs, "RAPPORT.md"))
  invisible(resultats)
}

if (sys.nframe() == 0L) executer_pipeline_horaire()
