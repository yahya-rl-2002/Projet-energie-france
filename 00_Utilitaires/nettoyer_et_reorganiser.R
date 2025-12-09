# =============================================================================
# NETTOYAGE ET RÉORGANISATION DES DONNÉES
# =============================================================================
# Ce script :
# 1. Archive les anciens résultats (calculés avec defi1, defi2, defi3)
# 2. Crée une structure pour les nouveaux résultats
# 3. Prépare l'environnement pour recalculer avec les nouvelles données RTE

# =============================================================================
# CONFIGURATION
# =============================================================================

# Déterminer le chemin data selon l'emplacement d'exécution
if (file.exists("data")) {
  CHEMIN_DATA <- "data"
} else if (file.exists("../data")) {
  CHEMIN_DATA <- "../data"
} else {
  CHEMIN_DATA <- "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION/data"
}

CHEMIN_ARCHIVE <- file.path(CHEMIN_DATA, "archive_anciennes_donnees")
CHEMIN_NOUVEAUX <- file.path(CHEMIN_DATA, "resultats_nouveaux")

# =============================================================================
# FICHIERS À ARCHIVER (anciens résultats)
# =============================================================================

fichiers_a_archiver <- c(
  # Prévisions
  "previsions_h1.csv",
  "previsions_h6.csv",
  "previsions_h12.csv",
  "previsions_h24.csv",
  "previsions_h48.csv",
  "previsions_h72.csv",
  "previsions_h168.csv",
  "previsions_h720.csv",
  "previsions_multi_horizons.csv",
  "previsions_scenarios.csv",
  "previsions_intervalles_confiance.csv",
  "evaluation_previsions.csv",
  
  # Validations
  "validation_croisee_temporelle.csv",
  "validation_croisee_blocs.csv",
  "validation_par_horizon.csv",
  "validation_intervalles.csv",
  
  # Robustesse
  "robustesse_outliers.csv",
  "robustesse_manquantes.csv",
  "robustesse_taille.csv",
  
  # Analyses
  "comparaison_modeles_finale.csv",
  "correlations_consommation.csv",
  "evolution_temporelle.csv",
  "pattern_horaire.csv",
  "pics_consommation.csv",
  "stats_par_saison.csv",
  "stats_par_type_jour.csv",
  "stats_saisonnalite.csv",
  "tendance_annuelle.csv",
  "analyse_erreurs.csv",
  "statistiques_scenarios.csv"
)

# =============================================================================
# FONCTION : CRÉER STRUCTURE
# =============================================================================

creer_structure <- function() {
  cat("📁 Création de la structure de dossiers...\n\n")
  
  # Créer dossier archive
  if (!dir.exists(CHEMIN_ARCHIVE)) {
    dir.create(CHEMIN_ARCHIVE, recursive = TRUE)
    cat("✅ Dossier créé:", CHEMIN_ARCHIVE, "\n")
  } else {
    cat("ℹ️  Dossier archive existe déjà:", CHEMIN_ARCHIVE, "\n")
  }
  
  # Créer structure pour nouveaux résultats
  dossiers_nouveaux <- c(
    file.path(CHEMIN_NOUVEAUX, "analyses"),
    file.path(CHEMIN_NOUVEAUX, "validations"),
    file.path(CHEMIN_NOUVEAUX, "previsions"),
    file.path(CHEMIN_NOUVEAUX, "modeles")
  )
  
  for (dossier in dossiers_nouveaux) {
    if (!dir.exists(dossier)) {
      dir.create(dossier, recursive = TRUE)
      cat("✅ Dossier créé:", dossier, "\n")
    } else {
      cat("ℹ️  Dossier existe déjà:", dossier, "\n")
    }
  }
  
  cat("\n")
}

# =============================================================================
# FONCTION : ARCHIVER ANCIENS RÉSULTATS
# =============================================================================

archiver_anciens_resultats <- function() {
  cat("📦 Archivage des anciens résultats...\n\n")
  
  fichiers_archives <- 0
  fichiers_manquants <- 0
  
  for (fichier in fichiers_a_archiver) {
    chemin_source <- file.path(CHEMIN_DATA, fichier)
    chemin_dest <- file.path(CHEMIN_ARCHIVE, fichier)
    
    if (file.exists(chemin_source)) {
      file.copy(chemin_source, chemin_dest, overwrite = TRUE)
      file.remove(chemin_source)
      fichiers_archives <- fichiers_archives + 1
      cat("   ✅ Archivé:", fichier, "\n")
    } else {
      fichiers_manquants <- fichiers_manquants + 1
      # Ne pas afficher les fichiers manquants pour éviter le bruit
    }
  }
  
  cat("\n✅", fichiers_archives, "fichiers archivés\n")
  if (fichiers_manquants > 0) {
    cat("ℹ️ ", fichiers_manquants, "fichiers n'existaient pas (déjà nettoyés ou jamais créés)\n")
  }
  cat("\n")
}

# =============================================================================
# FONCTION : VÉRIFIER NOUVEAU DATASET
# =============================================================================

verifier_nouveau_dataset <- function() {
  cat("🔍 Vérification du nouveau dataset...\n\n")
  
  chemin_dataset <- file.path(CHEMIN_DATA, "dataset_complet.csv")
  
  if (file.exists(chemin_dataset)) {
    tryCatch({
      df_full <- read.csv(chemin_dataset, stringsAsFactors = FALSE)
      df_full$Date <- as.POSIXct(df_full$Date)
      
      cat("   📊 Nombre d'observations:", nrow(df_full), "\n")
      cat("   📅 Première date:", format(min(df_full$Date, na.rm = TRUE), "%Y-%m-%d %H:%M:%S"), "\n")
      cat("   📅 Dernière date:", format(max(df_full$Date, na.rm = TRUE), "%Y-%m-%d %H:%M:%S"), "\n")
      cat("   📋 Nombre de colonnes:", ncol(df_full), "\n")
      cat("   ✅ Dataset prêt pour les nouvelles analyses\n\n")
    }, error = function(e) {
      cat("   ⚠️ Erreur lors de la lecture du dataset:", e$message, "\n\n")
    })
  } else {
    cat("   ⚠️ dataset_complet.csv non trouvé !\n")
    cat("   💡 Exécutez d'abord: source('01_Donnees/combinaison_donnees.R')\n\n")
  }
}

# =============================================================================
# FONCTION PRINCIPALE
# =============================================================================

nettoyer_et_reorganiser <- function() {
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  cat("🧹 NETTOYAGE ET RÉORGANISATION DES DONNÉES\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  cat("📂 Chemin data:", CHEMIN_DATA, "\n")
  cat("📦 Chemin archive:", CHEMIN_ARCHIVE, "\n")
  cat("🆕 Chemin nouveaux résultats:", CHEMIN_NOUVEAUX, "\n\n")
  
  # 1. Créer structure
  creer_structure()
  
  # 2. Archiver anciens résultats
  archiver_anciens_resultats()
  
  # 3. Vérifier nouveau dataset
  verifier_nouveau_dataset()
  
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  cat("✅ NETTOYAGE TERMINÉ\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  cat("📝 PROCHAINES ÉTAPES:\n")
  cat("   1. Exécuter les analyses: source('02_Analyse/analyse_exploratoire_avancee.R')\n")
  cat("   2. Exécuter les validations: source('04_Validation/executer_tous_validation.R')\n")
  cat("   3. Exécuter les prévisions: source('05_Prevision/executer_tous_prevision.R')\n\n")
}

# =============================================================================
# EXÉCUTION
# =============================================================================

# Exécuter automatiquement si le script est source
if (!interactive()) {
  nettoyer_et_reorganiser()
} else {
  # Si exécuté interactivement, proposer d'exécuter
  cat("💡 Pour exécuter le nettoyage, utilisez: nettoyer_et_reorganiser()\n")
}

