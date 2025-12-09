# 🚀 DÉMARRAGE SUR VOTRE MACHINE - GUIDE PAS À PAS

## 📋 ÉTAPE 1 : VÉRIFIER QUE R EST INSTALLÉ

### Sur Mac (votre cas)

```bash
# Ouvrir Terminal et vérifier
R --version
```

**Si R n'est pas installé** :
1. Aller sur https://cran.r-project.org
2. Cliquer sur "Download R for macOS"
3. Télécharger et installer le fichier `.pkg`

### Vérifier RStudio (Optionnel mais Recommandé)

```bash
# Vérifier si RStudio est installé
which rstudio
```

**Si RStudio n'est pas installé** :
1. Aller sur https://www.rstudio.com/products/rstudio/download/
2. Télécharger "RStudio Desktop" pour Mac
3. Installer

---

## 📋 ÉTAPE 2 : OUVRIR R OU RSTUDIO

### Option A : RStudio (Recommandé)

1. Ouvrir **RStudio**
2. Dans la console (en bas), vous verrez `>`
3. Vous êtes prêt !

### Option B : R en ligne de commande

1. Ouvrir **Terminal**
2. Taper `R` et appuyer sur Entrée
3. Vous verrez `>`
4. Vous êtes prêt !

---

## 📋 ÉTAPE 3 : INSTALLER LES PACKAGES R

### Dans RStudio ou R, copier-coller ce code :

```r
# Liste des packages nécessaires
packages <- c(
  "tidyverse",      # Manipulation de données
  "forecast",       # Séries temporelles (ARIMA, etc.)
  "tseries",        # Tests statistiques
  "urca",           # Tests de stationnarité
  "fpp3",           # Forecasting principles
  "lubridate",      # Dates
  "ggplot2",        # Visualisation
  "plotly",         # Graphiques interactifs
  "httr",           # Requêtes HTTP (pour APIs)
  "jsonlite",       # JSON
  "eurostat",       # Données Eurostat
  "quantmod",       # Données financières
  "rmarkdown",      # Rapports
  "knitr"           # Génération de rapports
)

# Installer les packages manquants
packages_a_installer <- packages[!packages %in% installed.packages()[,"Package"]]

if(length(packages_a_installer) > 0) {
  cat("Installation de", length(packages_a_installer), "packages...\n")
  install.packages(packages_a_installer, dependencies = TRUE)
  cat("✅ Installation terminée !\n")
} else {
  cat("✅ Tous les packages sont déjà installés !\n")
}

# Vérifier l'installation
cat("\n📦 Packages installés :\n")
for(pkg in packages) {
  if(require(pkg, character.only = TRUE, quietly = TRUE)) {
    cat("  ✅", pkg, "\n")
  } else {
    cat("  ❌", pkg, "(erreur)\n")
  }
}
```

**⏱️ Temps d'installation** : 5-15 minutes (selon votre connexion)

**💡 Note** : Si un package échoue, réessayez avec :
```r
install.packages("nom_du_package", dependencies = TRUE)
```

---

## 📋 ÉTAPE 4 : NAVIGUER VERS LE DOSSIER DU PROJET

### Dans RStudio ou R :

```r
# Voir le répertoire actuel
getwd()

# Aller dans le dossier du projet
setwd("/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION")

# Vérifier que vous êtes au bon endroit
getwd()

# Lister les fichiers
list.files()
```

**Vous devriez voir** :
- `01_Donnees/`
- `03_Modelisation/`
- `README_R.md`
- etc.

---

## 📋 ÉTAPE 5 : TEST RAPIDE (Sans Données Publiques)

### Test minimal pour vérifier que tout fonctionne :

```r
# Charger les packages
library(forecast)
library(tseries)

# Créer une série temporelle simple (test)
serie_test <- ts(rnorm(100), frequency = 24)

# Test : Ajuster un ARIMA simple
modele_test <- auto.arima(serie_test)

# Afficher le résultat
print(modele_test)

# Si vous voyez un résultat, c'est que ça fonctionne ! ✅
```

**Si ça fonctionne** : Vous pouvez passer à l'étape suivante !

**Si erreur** : Vérifier que les packages sont bien installés (étape 3)

---

## 📋 ÉTAPE 6 : CHARGER VOS DONNÉES (defi1, defi2, defi3)

### Vérifier que vos fichiers existent :

```r
# Vérifier que les fichiers existent
fichiers <- c("../../defi1.csv", "../../defi2.csv", "../../defi3.csv")

for(fichier in fichiers) {
  if(file.exists(fichier)) {
    cat("✅", fichier, "existe\n")
  } else {
    cat("❌", fichier, "N'EXISTE PAS\n")
  }
}
```

**Si les fichiers n'existent pas** :
- Vérifier le chemin
- Les fichiers doivent être dans : `/Volumes/YAHYA SSD/Documents/Serie temp/`

### Charger vos données :

```r
# Charger les données
defi1 <- read.csv("../../defi1.csv", sep = ";", encoding = "UTF-8")
defi2 <- read.csv("../../defi2.csv", sep = ";", encoding = "UTF-8")
defi3 <- read.csv("../../defi3.csv", sep = ";", encoding = "UTF-8")

# Voir les premières lignes
head(defi1)
head(defi2)
head(defi3)

# Voir les noms des colonnes
colnames(defi1)
```

**💡 Si erreur de séparateur** :
```r
# Essayer avec virgule
defi1 <- read.csv("../../defi1.csv", sep = ",", encoding = "UTF-8")
```

---

## 📋 ÉTAPE 7 : EXÉCUTER L'ANALYSE COMPLÈTE

### Option A : Utiliser le Script Complet (Recommandé)

```r
# Aller dans le dossier modélisation
setwd("03_Modelisation")

# Charger les fonctions
source("modeles_series_temporelles.R")

# Exécuter l'application complète
source("application_donnees_reelles.R")
```

**⏱️ Temps d'exécution** : 5-15 minutes (selon la taille des données)

**Résultats** :
- Graphiques dans `../figures/`
- Prévisions dans `../data/previsions_24h.csv`

### Option B : Exécution Manuelle Étape par Étape

```r
# 1. Charger les packages
library(forecast)
library(tseries)
library(urca)
library(ggplot2)

# 2. Charger vos données
defi1 <- read.csv("../../defi1.csv", sep = ";")
defi2 <- read.csv("../../defi2.csv", sep = ";")
defi3 <- read.csv("../../defi3.csv", sep = ";")

# 3. Identifier la colonne de consommation
# (Adapter selon vos fichiers)
col_conso <- grep("Consommation|consommation", colnames(defi1), 
                  value = TRUE, ignore.case = TRUE)[1]

# 4. Combiner les données
consommation <- c(defi1[[col_conso]], 
                  defi2[[col_conso]], 
                  defi3[[col_conso]])

# 5. Créer série temporelle
serie <- ts(consommation, frequency = 24)

# 6. Ajuster ARIMA automatique
modele <- auto.arima(serie)

# 7. Afficher le modèle
print(modele)
summary(modele)

# 8. Prévision pour 24h
prevision <- forecast(modele, h = 24)

# 9. Visualiser
plot(prevision)

# 10. Voir les valeurs
print(prevision$mean)
```

---

## 📋 ÉTAPE 8 : COLLECTER DONNÉES PUBLIQUES (Optionnel)

### Si vous voulez enrichir avec des données publiques :

```r
# Retourner au dossier racine
setwd("/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION")

# Créer le dossier data s'il n'existe pas
if(!dir.exists("data")) {
  dir.create("data")
}

# Charger le script de collecte
source("01_Donnees/collecte_donnees_publiques.R")

# Exécuter la collecte
collecte_toutes_donnees()
```

**💡 Note** : Certaines sources nécessitent des clés API (gratuites) :
- **INSEE** : https://api.insee.fr
- **Météo France** : https://portail-api.meteofrance.fr

**Si vous n'avez pas de clés API** : Le script fonctionnera quand même, mais certaines données ne seront pas collectées.

---

## 📋 ÉTAPE 9 : COMBINER TOUTES LES DONNÉES

### Si vous avez collecté des données publiques :

```r
# Charger le script de combinaison
source("01_Donnees/combinaison_donnees.R")

# Combiner toutes les données
dataset_complet <- combiner_toutes_donnees()

# Voir le résultat
head(dataset_complet)
summary(dataset_complet)
```

**Résultat** : Fichier `data/dataset_complet.csv` créé

---

## 📋 ÉTAPE 10 : GÉNÉRER LE RAPPORT

### Générer le rapport R Markdown :

```r
# Aller dans le dossier rapport
setwd("07_Rapport")

# Charger rmarkdown
library(rmarkdown)

# Générer le PDF
render("rapport.Rmd", output_format = "pdf_document")

# OU générer le HTML
render("rapport.Rmd", output_format = "html_document")
```

**Résultat** : `rapport.pdf` ou `rapport.html` créé

**💡 Si erreur LaTeX** : Installer MacTeX ou utiliser HTML

---

## 🐛 RÉSOLUTION DE PROBLÈMES

### Erreur : "Package non trouvé"

```r
# Installer le package manuellement
install.packages("nom_du_package", dependencies = TRUE)
```

### Erreur : "Fichier non trouvé"

```r
# Vérifier le répertoire actuel
getwd()

# Vérifier que le fichier existe
file.exists("chemin/vers/fichier.csv")

# Changer de répertoire si nécessaire
setwd("/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION")
```

### Erreur : "Encodage"

```r
# Essayer différents encodages
read.csv("fichier.csv", encoding = "UTF-8")
read.csv("fichier.csv", encoding = "latin-1")
read.csv("fichier.csv", encoding = "ISO-8859-1")
```

### Erreur : "Séparateur"

```r
# Essayer différents séparateurs
read.csv("fichier.csv", sep = ";")
read.csv("fichier.csv", sep = ",")
read.csv("fichier.csv", sep = "\t")
```

### R est lent

```r
# Utiliser data.table pour grandes données
install.packages("data.table")
library(data.table)
data <- fread("fichier.csv")
```

---

## ✅ CHECKLIST DE DÉMARRAGE

Cochez au fur et à mesure :

- [ ] R installé et fonctionnel
- [ ] RStudio installé (optionnel)
- [ ] Packages R installés
- [ ] Navigation vers le dossier du projet réussie
- [ ] Test rapide fonctionne
- [ ] Données (defi1, defi2, defi3) chargées
- [ ] Analyse complète exécutée
- [ ] Graphiques générés
- [ ] Prévisions obtenues
- [ ] Rapport généré (optionnel)

---

## 🎯 EXEMPLE COMPLET EN UNE FOIS

### Script complet à copier-coller :

```r
# =============================================================================
# DÉMARRAGE COMPLET DU PROJET
# =============================================================================

# 1. Installer packages (si nécessaire)
packages <- c("tidyverse", "forecast", "tseries", "urca", "lubridate", 
              "ggplot2", "httr", "jsonlite")
install.packages(packages[!packages %in% installed.packages()[,"Package"]])

# 2. Charger les packages
library(forecast)
library(tseries)
library(ggplot2)

# 3. Aller dans le dossier du projet
setwd("/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION")

# 4. Charger vos données
defi1 <- read.csv("../../defi1.csv", sep = ";")
defi2 <- read.csv("../../defi2.csv", sep = ";")
defi3 <- read.csv("../../defi3.csv", sep = ";")

# 5. Identifier la colonne de consommation
col_conso <- grep("Consommation|consommation", colnames(defi1), 
                  value = TRUE, ignore.case = TRUE)[1]

# 6. Combiner les données
consommation <- c(defi1[[col_conso]], defi2[[col_conso]], defi3[[col_conso]])

# 7. Créer série temporelle
serie <- ts(consommation, frequency = 24)

# 8. Ajuster ARIMA automatique
cat("🔧 Ajustement du modèle ARIMA...\n")
modele <- auto.arima(serie)

# 9. Afficher le modèle
cat("\n📊 Modèle ajusté :\n")
print(modele)
summary(modele)

# 10. Prévision pour 24h
cat("\n🔮 Prévision pour les 24 prochaines heures...\n")
prevision <- forecast(modele, h = 24)

# 11. Visualiser
plot(prevision, main = "Prévision de la Consommation Électrique")

# 12. Afficher les valeurs
cat("\n📈 Prévisions :\n")
print(data.frame(
  Heure = 1:24,
  Prevision = prevision$mean,
  Lower_95 = prevision$lower[,2],
  Upper_95 = prevision$upper[,2]
))

cat("\n✅ TERMINÉ !\n")
```

**Copier-coller ce script dans RStudio et appuyer sur Entrée !**

---

## 📞 BESOIN D'AIDE ?

1. **Vérifier les erreurs** : Lire les messages d'erreur
2. **Vérifier les chemins** : Utiliser `getwd()` et `list.files()`
3. **Vérifier les packages** : Utiliser `installed.packages()`
4. **Consulter la documentation** : `README_R.md` et `GUIDE_DEMARRAGE_R.md`

---

**🇫🇷 Bonne chance ! Vous allez y arriver !** 🚀

