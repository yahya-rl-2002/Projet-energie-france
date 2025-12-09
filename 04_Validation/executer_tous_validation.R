# =============================================================================
# SCRIPT MAÎTRE - EXÉCUTER TOUS LES SCRIPTS DE VALIDATION
# =============================================================================
# Ce script exécute tous les scripts de validation et sauvegarde tous les logs

# Configurer miroir CRAN
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Créer dossier logs
if (!dir.exists("logs")) {
  dir.create("logs", recursive = TRUE)
}

# Nom du fichier de log principal avec timestamp
timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
fichier_log_principal <- paste0("logs/execution_complete_validation_", timestamp, ".log")

# Ouvrir le fichier de log principal
sink(fichier_log_principal, split = TRUE)

cat("=", paste0(rep("=", 78), collapse = ""), "=\n", sep = "")
cat("🚀 EXÉCUTION COMPLÈTE DE TOUS LES SCRIPTS DE VALIDATION\n")
cat("=", paste0(rep("=", 78), collapse = ""), "=\n", sep = "")
cat("Date de début:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")

# =============================================================================
# 1. VALIDATION CROISÉE
# =============================================================================

cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
cat("1️⃣ VALIDATION CROISÉE\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

tryCatch({
  source("04_Validation/validation_croisee.R")
  cat("✅ Validation croisée terminée\n\n")
}, error = function(e) {
  cat("❌ Erreur dans validation_croisee.R:\n")
  cat(toString(e), "\n\n")
})

# =============================================================================
# 2. TESTS DE ROBUSTESSE
# =============================================================================

cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
cat("2️⃣ TESTS DE ROBUSTESSE\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

tryCatch({
  source("04_Validation/tests_robustesse.R")
  cat("✅ Tests de robustesse terminés\n\n")
}, error = function(e) {
  cat("❌ Erreur dans tests_robustesse.R:\n")
  cat(toString(e), "\n\n")
})

# =============================================================================
# 3. VALIDATION DES PRÉVISIONS
# =============================================================================

cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
cat("3️⃣ VALIDATION DES PRÉVISIONS\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

tryCatch({
  source("04_Validation/validation_previsions.R")
  cat("✅ Validation des prévisions terminée\n\n")
}, error = function(e) {
  cat("❌ Erreur dans validation_previsions.R:\n")
  cat(toString(e), "\n\n")
})

# =============================================================================
# 4. COMPARAISON AVANCÉE
# =============================================================================

cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
cat("4️⃣ COMPARAISON AVANCÉE DES MODÈLES\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

tryCatch({
  source("04_Validation/comparaison_modeles_avancee.R")
  cat("✅ Comparaison avancée terminée\n\n")
}, error = function(e) {
  cat("❌ Erreur dans comparaison_modeles_avancee.R:\n")
  cat(toString(e), "\n\n")
})

# =============================================================================
# RÉSUMÉ FINAL
# =============================================================================

cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
cat("📊 RÉSUMÉ DE L'EXÉCUTION\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

cat("Date de fin:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")

cat("📁 Fichiers de logs créés dans le dossier 'logs/':\n")
logs_crees <- list.files("logs", pattern = paste0(".*", timestamp, ".*"), full.names = FALSE)
if (length(logs_crees) > 0) {
  for (log in logs_crees) {
    cat("   -", log, "\n")
  }
} else {
  cat("   (Aucun log trouvé)\n")
}

cat("\n📁 Fichiers de résultats créés dans le dossier 'data/':\n")
resultats_crees <- list.files("data", pattern = "validation|robustesse|comparaison", full.names = FALSE)
if (length(resultats_crees) > 0) {
  for (res in resultats_crees) {
    cat("   -", res, "\n")
  }
} else {
  cat("   (Aucun résultat trouvé)\n")
}

cat("\n📁 Graphiques créés dans le dossier 'figures/':\n")
figures_crees <- list.files("figures", pattern = "validation|robustesse|comparaison|erreurs", full.names = FALSE)
if (length(figures_crees) > 0) {
  for (fig in figures_crees) {
    cat("   -", fig, "\n")
  }
} else {
  cat("   (Aucun graphique trouvé)\n")
}

cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
cat("✅ EXÉCUTION COMPLÈTE TERMINÉE\n")
cat("📁 Log principal sauvegardé:", fichier_log_principal, "\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

sink()  # Fermer le fichier de log principal

