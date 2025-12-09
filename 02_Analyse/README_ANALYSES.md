# 📊 GUIDE DES ANALYSES AVANCÉES

## 🎯 Vue d'ensemble

Ce dossier contient **6 scripts d'analyses avancées** pour explorer en profondeur votre dataset complet.

---

## 📁 Scripts disponibles

### 1. `analyse_exploratoire_avancee.R`
**Objectif** : Analyses statistiques détaillées et identification des périodes clés

**Fonctionnalités** :
- ✅ Statistiques descriptives complètes
- ✅ Analyse des distributions (skewness, kurtosis, normalité)
- ✅ Analyse des tendances (annuelles, mensuelles)
- ✅ Identification des jours avec consommation max/min
- ✅ Détection des pics de consommation

**Résultats** :
- `figures/distributions_consommation.png`
- `figures/tendance_consommation.png`
- `data/stats_par_type_jour.csv`
- `data/stats_par_saison.csv`
- `data/tendance_annuelle.csv`

**Exécution** :
```r
source("02_Analyse/analyse_exploratoire_avancee.R")
resultats <- analyser_dataset_complet()
```

---

### 2. `correlations_detaillees.R`
**Objectif** : Analyse complète des corrélations entre toutes les variables

**Fonctionnalités** :
- ✅ Matrice de corrélations complète
- ✅ Corrélations par saison
- ✅ Corrélations par type de jour
- ✅ Corrélations par couleur TEMPO
- ✅ Scatter plots avec régression

**Résultats** :
- `figures/matrice_correlations.png` (heatmap)
- `figures/scatter_correlations.png`
- `data/correlations_consommation.csv`

**Exécution** :
```r
source("02_Analyse/correlations_detaillees.R")
resultats <- analyser_correlations_completes()
```

---

### 3. `analyse_saisonnalite.R`
**Objectif** : Analyse détaillée des patterns saisonniers

**Fonctionnalités** :
- ✅ Décomposition saisonnière avancée (STL)
- ✅ Analyse par saison météorologique
- ✅ Patterns hebdomadaires
- ✅ Patterns mensuels
- ✅ Patterns horaires
- ✅ Impact des jours fériés et week-ends

**Résultats** :
- `figures/decomposition_saisonniere_avancee.png`
- `figures/consommation_par_saison.png`
- `figures/pattern_hebdomadaire.png`
- `figures/pattern_mensuel.png`
- `figures/pattern_horaire.png`
- `data/stats_saisonnalite.csv`

**Exécution** :
```r
source("02_Analyse/analyse_saisonnalite.R")
resultats <- analyser_saisonnalite_complete()
```

---

### 4. `detection_anomalies.R`
**Objectif** : Détection des valeurs aberrantes et des jours exceptionnels

**Fonctionnalités** :
- ✅ Détection par méthode IQR (Interquartile Range)
- ✅ Détection par Z-Score
- ✅ Détection des pics de consommation
- ✅ Détection d'anomalies par heure
- ✅ Visualisation des anomalies

**Résultats** :
- `figures/anomalies_iqr.png`
- `figures/anomalies_zscore.png`
- `figures/boxplot_anomalies.png`
- `data/pics_consommation.csv`

**Exécution** :
```r
source("02_Analyse/detection_anomalies.R")
resultats <- detecter_toutes_anomalies()
```

---

### 5. `analyse_patterns_temporels.R`
**Objectif** : Analyse détaillée des patterns horaires, journaliers, hebdomadaires

**Fonctionnalités** :
- ✅ Patterns horaires détaillés (avec écart-type)
- ✅ Patterns par type de jour
- ✅ Patterns par saison
- ✅ Patterns par couleur TEMPO
- ✅ Évolution temporelle des patterns
- ✅ Comparaisons (week-ends vs jours ouvrables, fériés vs normaux)

**Résultats** :
- `figures/pattern_horaire_detaille.png`
- `figures/pattern_horaire_par_type_jour.png`
- `figures/pattern_horaire_par_saison.png`
- `figures/pattern_horaire_par_tempo.png`
- `figures/evolution_temporelle.png`
- `figures/comparaison_weekend.png`
- `figures/comparaison_ferie.png`
- `data/pattern_horaire.csv`
- `data/evolution_temporelle.csv`

**Exécution** :
```r
source("02_Analyse/analyse_patterns_temporels.R")
resultats <- analyser_patterns_temporels_complets()
```

---

### 6. `visualisations_creatives.R`
**Objectif** : Graphiques interactifs et visualisations avancées

**Fonctionnalités** :
- ✅ Graphiques interactifs (Plotly) - HTML
- ✅ Heatmap de consommation (jour × heure)
- ✅ Graphiques multi-variables
- ✅ Graphiques de corrélation avancés
- ✅ Graphiques 3D interactifs
- ✅ Dashboard visuel combiné

**Résultats** :
- `figures/consommation_interactif.html` (interactif)
- `figures/heatmap_consommation.png`
- `figures/multi_variables.png`
- `figures/correlation_avance.png`
- `figures/consommation_3d.html` (interactif)
- `figures/dashboard_visuel.png`

**Exécution** :
```r
source("02_Analyse/visualisations_creatives.R")
resultats <- creer_toutes_visualisations()
```

---

## 🚀 Exécution complète

### Option 1 : Exécuter tous les scripts

```r
# Aller dans le dossier du projet
setwd("/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION")

# 1. Analyse exploratoire
source("02_Analyse/analyse_exploratoire_avancee.R")
analyser_dataset_complet()

# 2. Corrélations
source("02_Analyse/correlations_detaillees.R")
analyser_correlations_completes()

# 3. Saisonnalité
source("02_Analyse/analyse_saisonnalite.R")
analyser_saisonnalite_complete()

# 4. Anomalies
source("02_Analyse/detection_anomalies.R")
detecter_toutes_anomalies()

# 5. Patterns temporels
source("02_Analyse/analyse_patterns_temporels.R")
analyser_patterns_temporels_complets()

# 6. Visualisations créatives
source("02_Analyse/visualisations_creatives.R")
creer_toutes_visualisations()
```

### Option 2 : Exécuter depuis le terminal

```bash
cd "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION"

# Exécuter chaque script
Rscript 02_Analyse/analyse_exploratoire_avancee.R
Rscript 02_Analyse/correlations_detaillees.R
Rscript 02_Analyse/analyse_saisonnalite.R
Rscript 02_Analyse/detection_anomalies.R
Rscript 02_Analyse/analyse_patterns_temporels.R
Rscript 02_Analyse/visualisations_creatives.R
```

---

## 📦 Packages requis

Tous les scripts installent automatiquement les packages manquants, mais vous pouvez les installer à l'avance :

```r
install.packages(c(
  "tidyverse",
  "lubridate",
  "ggplot2",
  "plotly",
  "corrplot",
  "forecast",
  "gridExtra",
  "viridis",
  "htmlwidgets",
  "moments"
))
```

---

## 📊 Résultats attendus

Après exécution de tous les scripts, vous aurez :

- **~30 graphiques** dans `figures/`
- **~10 fichiers CSV** avec statistiques dans `data/`
- **2 graphiques interactifs HTML** (ouvrables dans un navigateur)

---

## 💡 Conseils d'utilisation

1. **Exécutez dans l'ordre** : Commencez par `analyse_exploratoire_avancee.R` pour avoir une vue d'ensemble
2. **Temps d'exécution** : Chaque script prend 1-5 minutes selon la taille des données
3. **Graphiques interactifs** : Ouvrez les fichiers `.html` dans un navigateur pour explorer
4. **Personnalisation** : Modifiez les seuils et paramètres dans les scripts selon vos besoins

---

## 🔍 Exemples d'utilisation des résultats

### Analyser les corrélations

```r
# Charger les corrélations
cor_df <- read.csv("data/correlations_consommation.csv")

# Variables les plus corrélées avec consommation
head(cor_df %>% arrange(desc(abs(Correlation))), 10)
```

### Identifier les jours avec pics

```r
# Charger les pics
pics <- read.csv("data/pics_consommation.csv")

# Jours avec le plus de pics
head(pics %>% arrange(desc(Nombre_pics)), 10)
```

### Analyser les patterns horaires

```r
# Charger les patterns
pattern <- read.csv("data/pattern_horaire.csv")

# Heures de pointe
head(pattern %>% arrange(desc(Consommation_moyenne)), 5)
```

---

## ✅ Checklist

- [ ] Dataset complet créé (`data/dataset_complet.csv`)
- [ ] Scripts d'analyse dans `02_Analyse/`
- [ ] Packages installés
- [ ] Scripts exécutés
- [ ] Graphiques générés dans `figures/`
- [ ] Statistiques sauvegardées dans `data/`

---

**🎉 Bonne analyse !**

