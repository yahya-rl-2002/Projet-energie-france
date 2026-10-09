# =============================================================================
# SCRIPT MAÎTRE - EXÉCUTER TOUS LES SCRIPTS DE PRÉVISION
# =============================================================================
# Ce script exécute tous les scripts de prévision et sauvegarde tous les logs

# Configurer miroir CRAN
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# Créer dossier logs
if (!dir.exists("logs")) {
  dir.create("logs", recursive = TRUE)
}

# Nom du fichier de log principal avec timestamp
timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
fichier_log_principal <- paste0("logs/execution_complete_prevision_", timestamp, ".log")

# Ouvrir le fichier de log principal
sink(fichier_log_principal, split = TRUE)

cat("=", paste0(rep("=", 78), collapse = ""), "=\n", sep = "")
cat("🚀 EXÉCUTION COMPLÈTE DE TOUS LES SCRIPTS DE PRÉVISION\n")
cat("=", paste0(rep("=", 78), collapse = ""), "=\n", sep = "")
cat("Date de début:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n\n")

# =============================================================================
# 1. PRÉVISIONS MULTI-HORIZONS
# =============================================================================

cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
cat("1️⃣ PRÉVISIONS MULTI-HORIZONS\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

tryCatch({
  source("05_Prevision/previsions_multi_horizons.R")
  cat("✅ Prévisions multi-horizons terminées\n\n")
}, error = function(e) {
  cat("❌ Erreur dans previsions_multi_horizons.R:\n")
  cat(toString(e), "\n\n")
})

# =============================================================================
# 2. ANALYSE DES SCÉNARIOS
# =============================================================================

cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
cat("2️⃣ ANALYSE DES SCÉNARIOS\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

tryCatch({
  source("05_Prevision/analyse_scenarios.R")
  cat("✅ Analyse des scénarios terminée\n\n")
}, error = function(e) {
  cat("❌ Erreur dans analyse_scenarios.R:\n")
  cat(toString(e), "\n\n")
})

# =============================================================================
# 3. INTERVALLES DE CONFIANCE
# =============================================================================

cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
cat("3️⃣ INTERVALLES DE CONFIANCE\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

tryCatch({
  source("05_Prevision/intervalles_confiance.R")
  cat("✅ Analyse des intervalles de confiance terminée\n\n")
}, error = function(e) {
  cat("❌ Erreur dans intervalles_confiance.R:\n")
  cat(toString(e), "\n\n")
})

# =============================================================================
# 4. ÉVALUATION DES PRÉVISIONS
# =============================================================================

cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
cat("4️⃣ ÉVALUATION DES PRÉVISIONS\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

tryCatch({
  source("05_Prevision/evaluation_previsions.R")
  cat("✅ Évaluation des prévisions terminée\n\n")
}, error = function(e) {
  cat("❌ Erreur dans evaluation_previsions.R:\n")
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
resultats_crees <- list.files("data", pattern = "prevision|scenario|intervalle|evaluation", full.names = FALSE)
if (length(resultats_crees) > 0) {
  for (res in resultats_crees) {
    cat("   -", res, "\n")
  }
} else {
  cat("   (Aucun résultat trouvé)\n")
}

cat("\n📁 Graphiques créés dans le dossier 'figures/':\n")
figures_crees <- list.files("figures", pattern = "prevision|scenario|intervalle|evaluation", full.names = FALSE)
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


