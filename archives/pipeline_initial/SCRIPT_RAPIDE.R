# =============================================================================
# 🚀 SCRIPT RAPIDE - TOUT EN UN
# =============================================================================
# Copier-coller TOUT ce fichier dans R pour tout faire d'un coup !
# =============================================================================

cat("╔══════════════════════════════════════════════════════════════════════════════╗\n")
cat("║                    🚀 DÉMARRAGE AUTOMATIQUE                                 ║\n")
cat("╚══════════════════════════════════════════════════════════════════════════════╝\n\n")

# =============================================================================
# ÉTAPE 1 : ALLER DANS LE BON DOSSIER
# =============================================================================

cat("📂 ÉTAPE 1 : Vérification du dossier...\n")
chemin_projet <- "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION"

if (dir.exists(chemin_projet)) {
  setwd(chemin_projet)
  cat("✅ Dossier correct :", getwd(), "\n\n")
} else {
  cat("❌ ERREUR : Dossier non trouvé !\n")
  cat("   Vérifiez que vous êtes au bon endroit.\n")
  stop("Arrêt du script")
}

# =============================================================================
# ÉTAPE 2 : VÉRIFIER LES FICHIERS NÉCESSAIRES
# =============================================================================

cat("📋 ÉTAPE 2 : Vérification des fichiers...\n")

# Vérifier defi1, defi2, defi3
chemin_base <- "/Volumes/YAHYA SSD/Documents/Serie temp"
fichiers_necessaires <- c(
  paste0(chemin_base, "/defi1.csv"),
  paste0(chemin_base, "/defi2.csv"),
  paste0(chemin_base, "/defi3.csv")
)

tous_presents <- TRUE
for (fichier in fichiers_necessaires) {
  if (file.exists(fichier)) {
    cat("✅", basename(fichier), "trouvé\n")
  } else {
    cat("❌", basename(fichier), "NON TROUVÉ !\n")
    tous_presents <- FALSE
  }
}

if (!tous_presents) {
  cat("\n⚠️ ATTENTION : Certains fichiers manquent !\n")
  cat("   Le script continuera mais peut échouer.\n\n")
} else {
  cat("✅ Tous les fichiers nécessaires sont présents !\n\n")
}

# =============================================================================
# ÉTAPE 3 : INSTALLER LES PACKAGES (si nécessaire)
# =============================================================================

cat("📦 ÉTAPE 3 : Vérification des packages...\n")

packages_necessaires <- c(
  "tidyverse", "forecast", "tseries", "urca", 
  "ggplot2", "lubridate", "rmarkdown", "knitr", "kableExtra"
)

packages_manquants <- packages_necessaires[!packages_necessaires %in% installed.packages()[,"Package"]]

if (length(packages_manquants) > 0) {
  cat("⚠️ Packages manquants :", paste(packages_manquants, collapse = ", "), "\n")
  cat("   Installation en cours... (peut prendre 5-10 minutes)\n")
  
  tryCatch({
    install.packages(packages_manquants, dependencies = TRUE)
    cat("✅ Packages installés avec succès !\n\n")
  }, error = function(e) {
    cat("❌ Erreur lors de l'installation :", e$message, "\n")
    cat("   Vous pouvez installer manuellement avec :\n")
    cat("   install.packages(c(", paste0('"', packages_manquants, '"', collapse = ", "), "))\n\n")
  })
} else {
  cat("✅ Tous les packages sont déjà installés !\n\n")
}

# =============================================================================
# ÉTAPE 4 : COMBINER LES DONNÉES
# =============================================================================

cat("🔗 ÉTAPE 4 : Combinaison des données...\n")

if (file.exists("01_Donnees/combinaison_donnees.R")) {
  tryCatch({
    source("01_Donnees/combinaison_donnees.R")
    
    # Vérifier si dataset existe déjà
    if (file.exists("01_Donnees/data/dataset_complet.csv")) {
      cat("✅ Dataset complet existe déjà !\n")
      cat("   Chargement...\n")
      dataset_complet <- read.csv("01_Donnees/data/dataset_complet.csv")
      cat("✅ Dataset chargé :", nrow(dataset_complet), "observations\n\n")
    } else {
      cat("   Création du dataset complet...\n")
      dataset_complet <- combiner_toutes_donnees()
      cat("✅ Dataset créé :", nrow(dataset_complet), "observations\n\n")
    }
  }, error = function(e) {
    cat("❌ Erreur lors de la combinaison :", e$message, "\n\n")
  })
} else {
  cat("❌ Fichier combinaison_donnees.R non trouvé !\n\n")
}

# =============================================================================
# ÉTAPE 5 : FAIRE LA MODÉLISATION
# =============================================================================

cat("🔬 ÉTAPE 5 : Modélisation...\n")
cat("   ⏱️ Cette étape peut prendre 5-10 minutes...\n\n")

if (file.exists("03_Modelisation/application_donnees_reelles.R")) {
  tryCatch({
    # Aller dans le dossier modélisation
    dossier_actuel <- getwd()
    setwd("03_Modelisation")
    
    # Charger les fonctions
    source("modeles_series_temporelles.R")
    
    # Appliquer sur les données
    source("application_donnees_reelles.R")
    
    # Revenir au dossier principal
    setwd(dossier_actuel)
    
    cat("\n✅ Modélisation terminée !\n\n")
  }, error = function(e) {
    cat("❌ Erreur lors de la modélisation :", e$message, "\n")
    cat("   Vérifiez les messages d'erreur ci-dessus.\n\n")
  })
} else {
  cat("❌ Fichier application_donnees_reelles.R non trouvé !\n\n")
}

# =============================================================================
# ÉTAPE 6 : RÉSUMÉ DES RÉSULTATS
# =============================================================================

cat("╔══════════════════════════════════════════════════════════════════════════════╗\n")
cat("║                    ✅ RÉSUMÉ DES RÉSULTATS                                   ║\n")
cat("╚══════════════════════════════════════════════════════════════════════════════╝\n\n")

# Vérifier les fichiers créés
fichiers_resultats <- list(
  "Dataset complet" = "01_Donnees/data/dataset_complet.csv",
  "Graphique ACF/PACF" = "figures/acf_pacf_Consommation_Electrique_France.png",
  "Décomposition" = "figures/decomposition_Consommation_Electrique_France.png",
  "Prévisions 24h" = "data/previsions_24h.csv",
  "Comparaison modèles" = "data/comparaison_modeles.csv"
)

cat("📊 Fichiers créés :\n")
for (nom in names(fichiers_resultats)) {
  chemin <- fichiers_resultats[[nom]]
  if (file.exists(chemin)) {
    taille <- file.info(chemin)$size
    cat("   ✅", nom, ":", chemin, "(", round(taille/1024, 2), "KB)\n")
  } else {
    cat("   ❌", nom, ":", chemin, "(NON TROUVÉ)\n")
  }
}

cat("\n")

# Afficher les prévisions si disponibles
if (file.exists("data/previsions_24h.csv")) {
  cat("📈 Prévisions pour les 24 prochaines heures :\n")
  prev <- read.csv("data/previsions_24h.csv")
  print(head(prev, 5))
  cat("   ... (voir data/previsions_24h.csv pour toutes les prévisions)\n\n")
}

# Afficher la comparaison des modèles si disponible
if (file.exists("data/comparaison_modeles.csv")) {
  cat("🏆 Comparaison des modèles :\n")
  comp <- read.csv("data/comparaison_modeles.csv")
  print(comp)
  cat("\n")
}

# =============================================================================
# ÉTAPE 7 : PROCHAINES ÉTAPES
# =============================================================================

cat("╔══════════════════════════════════════════════════════════════════════════════╗\n")
cat("║                    📚 PROCHAINES ÉTAPES                                      ║\n")
cat("╚══════════════════════════════════════════════════════════════════════════════╝\n\n")

cat("1. Voir les graphiques :\n")
cat("   → Ouvrir le dossier 'figures/'\n\n")

cat("2. Voir les prévisions :\n")
cat("   → Ouvrir 'data/previsions_24h.csv'\n\n")

cat("3. Générer le rapport (optionnel) :\n")
cat("   → setwd('07_Rapport')\n")
cat("   → render('rapport.Rmd', output_format = 'html_document')\n\n")

cat("4. Lire le guide simple :\n")
cat("   → Ouvrir 'GUIDE_SIMPLE_DEBUT.md'\n\n")

cat("╔══════════════════════════════════════════════════════════════════════════════╗\n")
cat("║                    🎉 TERMINÉ !                                              ║\n")
cat("╚══════════════════════════════════════════════════════════════════════════════╝\n\n")

cat("✅ Le script est terminé !\n")
cat("✅ Tous les fichiers ont été créés dans leurs dossiers respectifs.\n\n")

cat("💡 Besoin d'aide ? Lisez GUIDE_SIMPLE_DEBUT.md\n\n")

