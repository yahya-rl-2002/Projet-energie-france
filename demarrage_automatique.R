# =============================================================================
# SCRIPT DE DÉMARRAGE AUTOMATIQUE
# =============================================================================
# Copier-coller ce script dans RStudio et appuyer sur Entrée !

cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("🚀 DÉMARRAGE AUTOMATIQUE DU PROJET\n")
cat("=" %&% strrep("=", 80) %&% "\n\n")

# =============================================================================
# ÉTAPE 1 : INSTALLER LES PACKAGES
# =============================================================================

cat("📦 ÉTAPE 1 : Installation des packages...\n")
cat(paste0(rep("-", 80), collapse = ""), "\n")

packages <- c(
  "tidyverse",      # Manipulation de données
  "forecast",       # Séries temporelles
  "tseries",        # Tests statistiques
  "urca",           # Tests de stationnarité
  "lubridate",      # Dates
  "ggplot2",        # Visualisation
  "httr",           # Requêtes HTTP
  "jsonlite"        # JSON
)

packages_a_installer <- packages[!packages %in% installed.packages()[,"Package"]]

if(length(packages_a_installer) > 0) {
  cat("Installation de", length(packages_a_installer), "packages...\n")
  install.packages(packages_a_installer, dependencies = TRUE)
  cat("✅ Packages installés !\n\n")
} else {
  cat("✅ Tous les packages sont déjà installés !\n\n")
}

# =============================================================================
# ÉTAPE 2 : CHARGER LES PACKAGES
# =============================================================================

cat("📚 ÉTAPE 2 : Chargement des packages...\n")
cat(paste0(rep("-", 80), collapse = ""), "\n")

library(forecast)
library(tseries)
library(urca)
library(ggplot2)
library(lubridate)

cat("✅ Packages chargés !\n\n")

# =============================================================================
# ÉTAPE 3 : NAVIGUER VERS LE DOSSIER DU PROJET
# =============================================================================

cat("📁 ÉTAPE 3 : Navigation vers le dossier du projet...\n")
cat(paste0(rep("-", 80), collapse = ""), "\n")

# Dossier actuel
dossier_actuel <- getwd()
cat("Dossier actuel :", dossier_actuel, "\n")

# Dossier du projet
dossier_projet <- "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION"

# Si on n'est pas dans le bon dossier, y aller
if(!grepl("R_VERSION", dossier_actuel)) {
  if(dir.exists(dossier_projet)) {
    setwd(dossier_projet)
    cat("✅ Changement vers :", getwd(), "\n\n")
  } else {
    cat("⚠️ Dossier du projet non trouvé. Création...\n")
    # Créer le dossier si nécessaire
    dir.create(dossier_projet, recursive = TRUE)
    setwd(dossier_projet)
    cat("✅ Dossier créé et navigation effectuée\n\n")
  }
} else {
  cat("✅ Déjà dans le bon dossier !\n\n")
}

# =============================================================================
# ÉTAPE 4 : VÉRIFIER LES FICHIERS DE DONNÉES
# =============================================================================

cat("📂 ÉTAPE 4 : Vérification des fichiers de données...\n")
cat(paste0(rep("-", 80), collapse = ""), "\n")

fichiers <- c(
  "../../defi1.csv",
  "../../defi2.csv",
  "../../defi3.csv"
)

fichiers_existants <- c()
for(fichier in fichiers) {
  if(file.exists(fichier)) {
    cat("✅", basename(fichier), "existe\n")
    fichiers_existants <- c(fichiers_existants, fichier)
  } else {
    cat("❌", basename(fichier), "N'EXISTE PAS\n")
  }
}

if(length(fichiers_existants) == 0) {
  cat("\n⚠️ ATTENTION : Aucun fichier de données trouvé !\n")
  cat("   Vérifiez que defi1.csv, defi2.csv, defi3.csv sont dans :\n")
  cat("   /Volumes/YAHYA SSD/Documents/Serie temp/\n\n")
  stop("Fichiers de données manquants")
}

cat("\n✅", length(fichiers_existants), "fichier(s) trouvé(s) !\n\n")

# =============================================================================
# ÉTAPE 5 : CHARGER LES DONNÉES
# =============================================================================

cat("📊 ÉTAPE 5 : Chargement des données...\n")
cat(paste0(rep("-", 80), collapse = ""), "\n")

# Fonction pour charger un fichier
charger_fichier <- function(fichier) {
  cat("Chargement de", basename(fichier), "...\n")
  
  # Essayer différents séparateurs et encodages
  tryCatch({
    df <- read.csv(fichier, sep = ";", encoding = "UTF-8")
    cat("  ✅ Chargé avec séparateur ';' et UTF-8\n")
    return(df)
  }, error = function(e1) {
    tryCatch({
      df <- read.csv(fichier, sep = ",", encoding = "UTF-8")
      cat("  ✅ Chargé avec séparateur ',' et UTF-8\n")
      return(df)
    }, error = function(e2) {
      tryCatch({
        df <- read.csv(fichier, sep = ";", encoding = "latin-1")
        cat("  ✅ Chargé avec séparateur ';' et latin-1\n")
        return(df)
      }, error = function(e3) {
        cat("  ❌ Erreur lors du chargement\n")
        return(NULL)
      })
    })
  })
}

# Charger tous les fichiers
donnees <- list()
for(fichier in fichiers_existants) {
  df <- charger_fichier(fichier)
  if(!is.null(df)) {
    donnees[[basename(fichier)]] <- df
  }
}

if(length(donnees) == 0) {
  stop("Aucune donnée n'a pu être chargée")
}

cat("\n✅", length(donnees), "fichier(s) chargé(s) !\n\n")

# =============================================================================
# ÉTAPE 6 : IDENTIFIER LA COLONNE DE CONSOMMATION
# =============================================================================

cat("🔍 ÉTAPE 6 : Identification de la colonne de consommation...\n")
cat(paste0(rep("-", 80), collapse = ""), "\n")

# Prendre le premier fichier comme référence
df_ref <- donnees[[1]]
col_conso <- grep("Consommation|consommation", colnames(df_ref), 
                  value = TRUE, ignore.case = TRUE)[1]

if(is.na(col_conso)) {
  # Essayer d'autres noms possibles
  col_conso <- grep("Conso|conso|Value|value|Valeur|valeur", 
                    colnames(df_ref), value = TRUE, ignore.case = TRUE)[1]
}

if(is.na(col_conso)) {
  cat("⚠️ Colonne de consommation non trouvée automatiquement.\n")
  cat("Colonnes disponibles :\n")
  print(colnames(df_ref))
  cat("\nVeuillez spécifier manuellement le nom de la colonne.\n")
  stop("Colonne de consommation non trouvée")
}

cat("✅ Colonne identifiée :", col_conso, "\n\n")

# =============================================================================
# ÉTAPE 7 : COMBINER LES DONNÉES
# =============================================================================

cat("🔗 ÉTAPE 7 : Combinaison des données...\n")
cat(paste0(rep("-", 80), collapse = ""), "\n")

consommation <- c()
for(nom_fichier in names(donnees)) {
  df <- donnees[[nom_fichier]]
  if(col_conso %in% colnames(df)) {
    valeurs <- df[[col_conso]]
    # Enlever les NA
    valeurs <- valeurs[!is.na(valeurs)]
    consommation <- c(consommation, valeurs)
    cat("✅", nom_fichier, ":", length(valeurs), "valeurs ajoutées\n")
  }
}

cat("\n✅ Total :", length(consommation), "observations\n\n")

# =============================================================================
# ÉTAPE 8 : CRÉER LA SÉRIE TEMPORELLE
# =============================================================================

cat("📈 ÉTAPE 8 : Création de la série temporelle...\n")
cat(paste0(rep("-", 80), collapse = ""), "\n")

serie <- ts(consommation, frequency = 24)

cat("✅ Série temporelle créée :\n")
cat("   Observations :", length(serie), "\n")
cat("   Fréquence :", frequency(serie), "h\n")
cat("   Min :", min(serie, na.rm = TRUE), "\n")
cat("   Max :", max(serie, na.rm = TRUE), "\n")
cat("   Moyenne :", round(mean(serie, na.rm = TRUE), 2), "\n\n")

# =============================================================================
# ÉTAPE 9 : AJUSTER LE MODÈLE ARIMA
# =============================================================================

cat("🔧 ÉTAPE 9 : Ajustement du modèle ARIMA...\n")
cat(paste0(rep("-", 80), collapse = ""), "\n")
cat("⏱️ Cela peut prendre quelques minutes...\n\n")

modele <- auto.arima(serie, 
                    max.p = 5, 
                    max.d = 2, 
                    max.q = 5,
                    seasonal = TRUE,
                    stepwise = TRUE,
                    approximation = FALSE,
                    trace = TRUE)

cat("\n✅ Modèle ajusté !\n\n")

# =============================================================================
# ÉTAPE 10 : AFFICHER LE RÉSULTAT
# =============================================================================

cat("📊 ÉTAPE 10 : Résultats du modèle...\n")
cat(paste0(rep("-", 80), collapse = ""), "\n")

print(modele)
summary(modele)

cat("\n")

# =============================================================================
# ÉTAPE 11 : PRÉVISION
# =============================================================================

cat("🔮 ÉTAPE 11 : Prévision pour les 24 prochaines heures...\n")
cat(paste0(rep("-", 80), collapse = ""), "\n")

prevision <- forecast(modele, h = 24, level = c(80, 95))

cat("✅ Prévisions générées !\n\n")

# Afficher les prévisions
resultats_prevision <- data.frame(
  Heure = 1:24,
  Prevision = round(prevision$mean, 2),
  Lower_80 = round(prevision$lower[,1], 2),
  Upper_80 = round(prevision$upper[,1], 2),
  Lower_95 = round(prevision$lower[,2], 2),
  Upper_95 = round(prevision$upper[,2], 2)
)

print(resultats_prevision)

cat("\n")

# =============================================================================
# ÉTAPE 12 : VISUALISATION
# =============================================================================

cat("📈 ÉTAPE 12 : Génération des graphiques...\n")
cat(paste0(rep("-", 80), collapse = ""), "\n")

# Créer le dossier figures si nécessaire
if(!dir.exists("figures")) {
  dir.create("figures", recursive = TRUE)
}

# Graphique de prévision
png("figures/prevision_automatique.png", width = 1600, height = 800)
plot(prevision, 
     main = "Prévision de la Consommation Électrique Française",
     xlab = "Temps",
     ylab = "Consommation (MW)",
     col = "blue",
     lwd = 2)
dev.off()

cat("✅ Graphique sauvegardé : figures/prevision_automatique.png\n\n")

# =============================================================================
# RÉSUMÉ FINAL
# =============================================================================

cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("✅ DÉMARRAGE TERMINÉ AVEC SUCCÈS !\n")
cat("=" %&% strrep("=", 80) %&% "\n\n")

cat("📊 Résumé :\n")
cat("   - Observations :", length(serie), "\n")
cat("   - Modèle :", modele$arma, "\n")
cat("   - AIC :", round(AIC(modele), 2), "\n")
cat("   - Prévisions : 24 heures\n")
cat("   - Graphique : figures/prevision_automatique.png\n\n")

cat("🎉 Tout fonctionne ! Vous pouvez maintenant :\n")
cat("   1. Explorer les résultats\n")
cat("   2. Utiliser les scripts avancés (application_donnees_reelles.R)\n")
cat("   3. Collecter des données publiques (collecte_donnees_publiques.R)\n")
cat("   4. Générer le rapport (rapport.Rmd)\n\n")

cat("📚 Documentation disponible :\n")
cat("   - DEMARRAGE_MACHINE.md : Guide détaillé\n")
cat("   - GUIDE_DEMARRAGE_R.md : Guide de démarrage\n")
cat("   - README_R.md : Documentation complète\n\n")

