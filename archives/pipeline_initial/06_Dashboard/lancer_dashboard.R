# =============================================================================
# SCRIPT DE LANCEMENT DU DASHBOARD
# =============================================================================
# Script pour lancer facilement le dashboard Shiny

# Configurer miroir CRAN
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# =============================================================================
# VÉRIFIER ET INSTALLER LES PACKAGES
# =============================================================================

packages_necessaires <- c(
  "shiny",
  "shinydashboard",
  "plotly",
  "DT",
  "tidyverse",
  "forecast",
  "lubridate"
)

cat("📦 Vérification des packages...\n\n")

for (pkg in packages_necessaires) {
  if (!require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("   Installation de", pkg, "...\n")
    install.packages(pkg, quiet = TRUE)
    library(pkg, character.only = TRUE)
  } else {
    cat("   ✅", pkg, "déjà installé\n")
  }
}

cat("\n✅ Tous les packages sont prêts\n\n")

# =============================================================================
# VÉRIFIER LES FICHIERS DE DONNÉES
# =============================================================================

cat("📂 Vérification des fichiers de données...\n\n")

# Déterminer le répertoire de travail
if (basename(getwd()) == "06_Dashboard") {
  # On est déjà dans 06_Dashboard
  chemin_data <- "../data/dataset_complet.csv"
} else {
  # On est dans R_VERSION
  chemin_data <- "data/dataset_complet.csv"
}

if (file.exists(chemin_data)) {
  cat("   ✅ Dataset principal trouvé:", chemin_data, "\n")
} else {
  cat("   ⚠️ Dataset principal non trouvé:", chemin_data, "\n")
  cat("      Le dashboard fonctionnera mais certaines fonctionnalités seront limitées.\n")
}

# Vérifier les prévisions
chemins_previsions <- c(
  "../data/previsions_multi_horizons.csv",
  "data/previsions_multi_horizons.csv"
)

previsions_trouvees <- FALSE
for (chemin in chemins_previsions) {
  if (file.exists(chemin)) {
    cat("   ✅ Prévisions trouvées:", chemin, "\n")
    previsions_trouvees <- TRUE
    break
  }
}

if (!previsions_trouvees) {
  cat("   ⚠️ Prévisions non trouvées. Exécutez d'abord:\n")
  cat("      source('05_Prevision/previsions_multi_horizons.R')\n")
}

cat("\n")

# =============================================================================
# LANCER LE DASHBOARD
# =============================================================================

cat("🚀 Lancement du dashboard...\n\n")
cat("=", paste0(rep("=", 78), collapse = ""), "=\n", sep = "")
cat("📊 DASHBOARD INTERACTIF - PRÉVISION DE CONSOMMATION ÉLECTRIQUE\n")
cat("=", paste0(rep("=", 78), collapse = ""), "=\n", sep = "")
cat("\n")
cat("Le dashboard va s'ouvrir dans votre navigateur.\n")
cat("Pour arrêter le dashboard, appuyez sur Ctrl+C (ou Cmd+C sur Mac)\n")
cat("\n")

# Déterminer le chemin de app.R
if (basename(getwd()) == "06_Dashboard") {
  chemin_app <- "app.R"
} else {
  chemin_app <- "06_Dashboard/app.R"
}

# Lancer l'application
shiny::runApp(chemin_app, launch.browser = TRUE)

