# =============================================================================
# ARCHIVAGE DES ANCIENS SCRIPTS DE CALCULS
# =============================================================================
# Ce script archive les anciens scripts qui ont été exécutés avec les
# anciennes données (defi1, defi2, defi3) pour faire place aux nouveaux
# calculs avec les données RTE complètes (2012-2025)

library(tidyverse)

# =============================================================================
# CONFIGURATION
# =============================================================================

CHEMIN_ARCHIVE_SCRIPTS <- "data/archive_anciens_scripts"
CHEMIN_PROJET <- getwd()

# Si on est dans un sous-dossier, remonter
if (basename(CHEMIN_PROJET) %in% c("00_Utilitaires", "01_Donnees", "02_Analyse", 
                                   "03_Modelisation", "04_Validation", "05_Prevision")) {
  CHEMIN_PROJET <- dirname(CHEMIN_PROJET)
}

# =============================================================================
# CRÉER DOSSIER D'ARCHIVE
# =============================================================================

if (!dir.exists(CHEMIN_ARCHIVE_SCRIPTS)) {
  dir.create(CHEMIN_ARCHIVE_SCRIPTS, recursive = TRUE)
  cat("✅ Dossier d'archive créé:", CHEMIN_ARCHIVE_SCRIPTS, "\n")
}

# =============================================================================
# SCRIPTS À ARCHIVER (si résultats existent avec anciennes données)
# =============================================================================

# Vérifier si des anciens résultats existent
anciens_resultats <- list.files("data", pattern = "\\.csv$", full.names = TRUE)
anciens_resultats <- anciens_resultats[!grepl("archive|dataset_complet|RTE|Calendrier|data_gouv|Meteo|INSEE|Eurostat|Yahoo", anciens_resultats)]

if (length(anciens_resultats) > 0) {
  cat("📦 Anciens résultats trouvés, archivage des scripts associés...\n\n")
  
  # Créer un timestamp pour l'archive
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  dossier_archive <- file.path(CHEMIN_ARCHIVE_SCRIPTS, paste0("scripts_", timestamp))
  dir.create(dossier_archive, recursive = TRUE)
  
  # Scripts potentiellement à archiver (si modifiés récemment)
  scripts_potentiels <- c(
    "02_Analyse/analyse_exploratoire_avancee.R",
    "02_Analyse/correlations_detaillees.R",
    "02_Analyse/analyse_saisonnalite.R",
    "02_Analyse/detection_anomalies.R",
    "02_Analyse/analyse_patterns_temporels.R",
    "03_Modelisation/application_donnees_reelles.R",
    "04_Validation/validation_croisee.R",
    "04_Validation/tests_robustesse.R",
    "04_Validation/validation_previsions.R",
    "04_Validation/comparaison_modeles_avancee.R",
    "05_Prevision/previsions_multi_horizons.R",
    "05_Prevision/analyse_scenarios.R",
    "05_Prevision/intervalles_confiance.R",
    "05_Prevision/evaluation_previsions.R"
  )
  
  scripts_archives <- 0
  
  for (script in scripts_potentiels) {
    chemin_script <- file.path(CHEMIN_PROJET, script)
    
    if (file.exists(chemin_script)) {
      # Copier le script dans l'archive
      dossier_dest <- file.path(dossier_archive, dirname(script))
      if (!dir.exists(dossier_dest)) {
        dir.create(dossier_dest, recursive = TRUE)
      }
      
      file.copy(chemin_script, file.path(dossier_dest, basename(script)), overwrite = TRUE)
      scripts_archives <- scripts_archives + 1
      cat("   ✅ Archivé:", script, "\n")
    }
  }
  
  # Créer un fichier README dans l'archive
  readme_archive <- file.path(dossier_archive, "README_ARCHIVE.txt")
  writeLines(
    c(
      "ARCHIVE DES ANCIENS SCRIPTS",
      paste("Date d'archivage:", Sys.time()),
      "",
      "Ces scripts ont été archivés car ils ont été exécutés avec les anciennes données",
      "(defi1, defi2, defi3). Les nouveaux scripts utiliseront les données RTE complètes",
      "(2012-2025) avec toutes les variables intégrées.",
      "",
      "Pour utiliser ces scripts archivés:",
      "1. Copier le script depuis ce dossier vers le dossier correspondant",
      "2. Vérifier que les chemins de données sont corrects",
      "3. Exécuter le script"
    ),
    readme_archive
  )
  
  cat("\n✅", scripts_archives, "scripts archivés dans:", dossier_archive, "\n")
} else {
  cat("ℹ️ Aucun ancien résultat trouvé, pas besoin d'archiver les scripts\n")
  cat("   Les scripts actuels sont déjà configurés pour les nouvelles données\n")
}

cat("\n")

