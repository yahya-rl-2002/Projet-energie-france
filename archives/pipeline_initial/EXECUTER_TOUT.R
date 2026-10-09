# =============================================================================
# SCRIPT MAÎTRE : EXÉCUTER TOUT LE PIPELINE
# =============================================================================
# Ce script exécute toutes les étapes du pipeline d'analyse avec le nouveau
# dataset complet (2012-2025)

cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("🚀 EXÉCUTION COMPLÈTE DU PIPELINE D'ANALYSE\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

# =============================================================================
# ÉTAPE 1 : ARCHIVAGE
# =============================================================================

cat("📦 ÉTAPE 1 : ARCHIVAGE DES ANCIENS RÉSULTATS\n")
cat(paste0(rep("-", 80), collapse = ""), "\n")

tryCatch({
  source("00_Utilitaires/nettoyer_et_reorganiser.R")
  nettoyer_et_reorganiser()
}, error = function(e) {
  cat("⚠️ Erreur lors de l'archivage:", e$message, "\n")
})

cat("\n")

# =============================================================================
# ÉTAPE 2 : ANALYSES EXPLORATOIRES
# =============================================================================

cat("📊 ÉTAPE 2 : ANALYSES EXPLORATOIRES\n")
cat(paste0(rep("-", 80), collapse = ""), "\n")

scripts_analyse <- c(
  "02_Analyse/analyse_exploratoire_avancee.R",
  "02_Analyse/correlations_detaillees.R",
  "02_Analyse/analyse_saisonnalite.R",
  "02_Analyse/detection_anomalies.R",
  "02_Analyse/analyse_patterns_temporels.R"
)

for (script in scripts_analyse) {
  if (file.exists(script)) {
    cat("   📄 Exécution:", script, "\n")
    tryCatch({
      source(script)
    }, error = function(e) {
      cat("   ⚠️ Erreur:", e$message, "\n")
    })
    cat("\n")
  }
}

# =============================================================================
# ÉTAPE 3 : MODÉLISATION
# =============================================================================

cat("🤖 ÉTAPE 3 : MODÉLISATION\n")
cat(paste0(rep("-", 80), collapse = ""), "\n")

if (file.exists("03_Modelisation/application_donnees_reelles.R")) {
  cat("   📄 Exécution: 03_Modelisation/application_donnees_reelles.R\n")
  tryCatch({
    source("03_Modelisation/application_donnees_reelles.R")
  }, error = function(e) {
    cat("   ⚠️ Erreur:", e$message, "\n")
  })
  cat("\n")
}

# =============================================================================
# ÉTAPE 4 : VALIDATION
# =============================================================================

cat("✅ ÉTAPE 4 : VALIDATION\n")
cat(paste0(rep("-", 80), collapse = ""), "\n")

if (file.exists("04_Validation/executer_tous_validation.R")) {
  cat("   📄 Exécution: 04_Validation/executer_tous_validation.R\n")
  tryCatch({
    source("04_Validation/executer_tous_validation.R")
  }, error = function(e) {
    cat("   ⚠️ Erreur:", e$message, "\n")
  })
  cat("\n")
}

# =============================================================================
# ÉTAPE 5 : PRÉVISIONS
# =============================================================================

cat("🔮 ÉTAPE 5 : PRÉVISIONS\n")
cat(paste0(rep("-", 80), collapse = ""), "\n")

if (file.exists("05_Prevision/executer_tous_prevision.R")) {
  cat("   📄 Exécution: 05_Prevision/executer_tous_prevision.R\n")
  tryCatch({
    source("05_Prevision/executer_tous_prevision.R")
  }, error = function(e) {
    cat("   ⚠️ Erreur:", e$message, "\n")
  })
  cat("\n")
}

# =============================================================================
# RÉSUMÉ
# =============================================================================

cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("✅ EXÉCUTION TERMINÉE\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

cat("📊 Résultats sauvegardés dans:\n")
cat("   - Analyses: data/resultats_nouveaux/analyses/\n")
cat("   - Modèles: data/resultats_nouveaux/modeles/\n")
cat("   - Validations: data/resultats_nouveaux/validations/\n")
cat("   - Prévisions: data/resultats_nouveaux/previsions/\n\n")

cat("🚀 Prochaines étapes:\n")
cat("   1. Lancer le dashboard: source('06_Dashboard/lancer_dashboard.R')\n")
cat("   2. Générer le rapport: rmarkdown::render('07_Rapport/rapport.Rmd')\n\n")

