# 🚀 GUIDE DE DÉMARRAGE RAPIDE - VERSION R

## 📋 PRÉREQUIS

### 1. Installer R
- **Windows/Mac** : https://cran.r-project.org
- **Linux** : `sudo apt-get install r-base`

### 2. Installer RStudio (Recommandé)
- **Télécharger** : https://www.rstudio.com/products/rstudio/download/

### 3. Installer les Packages R

Ouvrir RStudio et exécuter :

```r
# Liste des packages nécessaires
packages <- c(
  "tidyverse",      # Manipulation de données
  "forecast",       # Séries temporelles
  "tseries",        # Tests statistiques
  "urca",           # Tests de stationnarité
  "fpp3",           # Forecasting principles
  "lubridate",      # Dates
  "ggplot2",        # Visualisation
  "plotly",         # Graphiques interactifs
  "httr",           # Requêtes HTTP
  "jsonlite",       # JSON
  "eurostat",       # Données Eurostat
  "quantmod"        # Données financières
)

# Installer les packages manquants
install.packages(packages[!packages %in% installed.packages()])
```

---

## 🎯 ÉTAPES DE DÉMARRAGE

### Étape 1 : Collecter les Données Publiques (Optionnel mais Recommandé)

```r
# Aller dans le dossier du projet
setwd("PROJET_ENERGIE_FRANCE/R_VERSION")

# Charger le script de collecte
source("01_Donnees/collecte_donnees_publiques.R")

# Exécuter la collecte
collecte_toutes_donnees()
```

**Note** : Certaines sources nécessitent des clés API gratuites :
- **INSEE** : https://api.insee.fr
- **Météo France** : https://portail-api.meteofrance.fr
- **FRED** : https://fred.stlouisfed.org

### Étape 2 : Combiner Toutes les Données

```r
# Charger le script de combinaison
source("01_Donnees/combinaison_donnees.R")

# Combiner vos données (defi1, defi2, defi3) avec données publiques
dataset_complet <- combiner_toutes_donnees()
```

**Résultat** : Fichier `data/dataset_complet.csv` créé

### Étape 3 : Analyser et Modéliser

```r
# Aller dans le dossier modélisation
setwd("03_Modelisation")

# Charger les fonctions
source("modeles_series_temporelles.R")

# Appliquer sur vos données
source("application_donnees_reelles.R")
```

**Résultats** :
- Graphiques dans `figures/`
- Prévisions dans `data/previsions_24h.csv`
- Comparaison des modèles

---

## 📊 STRUCTURE DU PROJET

```
R_VERSION/
├── 01_Donnees/
│   ├── collecte_donnees_publiques.R    # Collecte données publiques
│   └── combinaison_donnees.R            # Combine toutes les données
│
├── 02_Analyse/
│   └── (À créer selon besoins)
│
├── 03_Modelisation/
│   ├── modeles_series_temporelles.R     # Toutes les méthodes
│   └── application_donnees_reelles.R    # Application pratique
│
├── 04_Validation/
│   └── (À créer selon besoins)
│
├── 05_Prevision/
│   └── (À créer selon besoins)
│
├── 06_Dashboard/
│   └── (Shiny app - optionnel)
│
├── 07_Rapport/
│   └── rapport.Rmd                      # Rapport R Markdown
│
├── data/                                # Données collectées
├── figures/                             # Graphiques générés
│
├── README_R.md                          # Ce fichier
└── SOURCES_DONNEES_PUBLIQUES.md         # Guide des sources
```

---

## 🔧 EXEMPLE D'UTILISATION RAPIDE

### Exemple Minimal (Sans Données Publiques)

```r
# 1. Charger vos données
defi1 <- read.csv("../../defi1.csv", sep = ";")
defi2 <- read.csv("../../defi2.csv", sep = ";")
defi3 <- read.csv("../../defi3.csv", sep = ";")

# 2. Combiner
consommation <- c(defi1$Consommation, defi2$Consommation, defi3$Consommation)

# 3. Créer série temporelle
library(forecast)
serie <- ts(consommation, frequency = 24)

# 4. Ajuster ARIMA automatique
modele <- auto.arima(serie)

# 5. Prévision
prevision <- forecast(modele, h = 24)
plot(prevision)
```

### Exemple Complet (Avec Données Publiques)

Voir `application_donnees_reelles.R`

---

## 📚 MÉTHODES DISPONIBLES

### Méthodes Classiques
- ✅ **Moyenne Mobile** : `ma()`
- ✅ **AR(p)** : `ajuster_AR()`
- ✅ **MA(q)** : `ajuster_MA()`
- ✅ **ARMA(p,q)** : `ajuster_ARMA()`
- ✅ **ARIMA(p,d,q)** : `ajuster_ARIMA_auto()`
- ✅ **SARIMA** : `ajuster_SARIMA_auto()`
- ✅ **SARIMAX** : `ajuster_SARIMAX()` (avec variables exogènes)

### Tests Statistiques
- ✅ **Dickey-Fuller** : Test de stationnarité
- ✅ **Ljung-Box** : Test des résidus
- ✅ **ACF/PACF** : Analyse d'autocorrélation

### Métriques
- ✅ **RMSE** : Root Mean Squared Error
- ✅ **MAE** : Mean Absolute Error
- ✅ **MAPE** : Mean Absolute Percentage Error
- ✅ **AIC/BIC** : Critères de sélection

---

## 🎓 POUR VOTRE PROFESSEUR

### Points à Mettre en Avant

1. **Utilisation de R** : Langage spécialisé statistiques
2. **Données Publiques** : Collecte depuis sources officielles
3. **Méthodes Complètes** : Toutes les méthodes du cours
4. **Validation Rigoureuse** : Tests statistiques, diagnostics
5. **Application Réelle** : Données françaises, contexte pratique

### Ce Que Vous Montrez

- ✅ Maîtrise de R et packages spécialisés
- ✅ Capacité à collecter et combiner données
- ✅ Application complète des méthodes classiques
- ✅ Validation statistique rigoureuse
- ✅ Prévisions avec intervalles de confiance

---

## 🐛 RÉSOLUTION DE PROBLÈMES

### Erreur : Package non trouvé
```r
install.packages("nom_du_package")
```

### Erreur : Données non trouvées
- Vérifier les chemins de fichiers
- Utiliser `getwd()` pour voir le répertoire courant
- Utiliser `setwd()` pour changer de répertoire

### Erreur : API non configurée
- Certaines données nécessitent des clés API
- Voir `SOURCES_DONNEES_PUBLIQUES.md` pour instructions

### Erreur : Mémoire insuffisante
- Utiliser `data.table` au lieu de `data.frame`
- Traiter les données par chunks

---

## 📖 RESSOURCES

### Documentation R
- **R Base** : https://cran.r-project.org/doc/manuals/
- **forecast** : https://pkg.robjhyndman.com/forecast/
- **tidyverse** : https://www.tidyverse.org/

### Tutoriels
- **R for Data Science** : https://r4ds.had.co.nz/
- **Forecasting** : https://otexts.com/fpp3/

### Communauté
- **Stack Overflow** : https://stackoverflow.com/questions/tagged/r
- **R-bloggers** : https://www.r-bloggers.com/

---

## ✅ CHECKLIST DE DÉMARRAGE

- [ ] R installé
- [ ] RStudio installé
- [ ] Packages R installés
- [ ] Données (defi1, defi2, defi3) disponibles
- [ ] Scripts chargés sans erreur
- [ ] Première analyse exécutée
- [ ] Graphiques générés
- [ ] Prévisions obtenues

---

## 🚀 PROCHAINES ÉTAPES

1. **Collecter données publiques** (si pas encore fait)
2. **Exécuter analyse complète**
3. **Interpréter les résultats**
4. **Créer rapport R Markdown**
5. **Préparer présentation**

---

**🇫🇷 Bonne chance avec votre projet en R !**


