# ⚡ Système Intelligent de Prévision de la Consommation Électrique Française

[![R](https://img.shields.io/badge/R-4.0+-blue.svg)](https://www.r-project.org/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)
[![Status](https://img.shields.io/badge/Status-Active-success.svg)]()

## 📋 Vue d'ensemble

Système complet de prévision de la consommation électrique française utilisant des méthodes avancées de séries temporelles (AR, MA, ARMA, ARIMA, SARIMA, SARIMAX) combinées avec des variables macroéconomiques et météorologiques.

### 🎯 Objectifs

- **Prévision multi-horizons** : 1h, 6h, 24h, 48h, 72h, 168h (1 semaine), 720h (1 mois)
- **Modélisation avancée** : 4 modèles de séries temporelles comparés
- **Validation rigoureuse** : Cross-validation, tests de robustesse, métriques complètes
- **Dashboard interactif** : Application Shiny pour visualisation et prévisions
- **Analyse de scénarios** : Optimiste, réaliste, pessimiste

## 📊 Données

### Sources de données (2012-2025)

- **RTE** : Consommation électrique horaire, production par source
- **Météo France / Open-Meteo** : Températures historiques et prévisions
- **INSEE** : PIB, chômage, inflation
- **Eurostat** : Données européennes comparatives
- **data.gouv.fr** : Données publiques françaises
- **Calendrier français** : Jours fériés, TEMPO, weekends

### Dataset final

- **1,154,808 observations** horaires
- **47 variables** (consommation, température, variables économiques, calendrier)
- **Période** : 2012-01-01 à 2025-11-13

## 🔬 Méthodologie

### Modèles implémentés

1. **ETS** (Error, Trend, Seasonality)
2. **ARIMA** (Auto-ARIMA avec optimisation AIC)
3. **TBATS** (Trigonometric seasonality)
4. **SARIMAX** (avec variables exogènes : température, PIB, calendrier)

### Analyses réalisées

- ✅ Analyse exploratoire avancée
- ✅ Corrélations détaillées
- ✅ Analyse de saisonnalité (STL decomposition)
- ✅ Détection d'anomalies (IQR, Z-score)
- ✅ Analyse des patterns temporels
- ✅ Validation croisée temporelle
- ✅ Tests de robustesse
- ✅ Comparaison avancée des modèles

### Métriques d'évaluation

- **RMSE** (Root Mean Squared Error)
- **MAE** (Mean Absolute Error)
- **MAPE** (Mean Absolute Percentage Error)
- **R²** (Coefficient of Determination)
- **MASE** (Mean Absolute Scaled Error)
- **sMAPE** (Symmetric MAPE)
- **Theil's U**
- **Directional Accuracy**
- **Coverage des intervalles de confiance**

## 📁 Structure du projet

```
R_VERSION/
├── 00_Utilitaires/          # Scripts utilitaires
│   ├── chemins_resultats.R
│   ├── archiver_anciens_scripts.R
│   └── nettoyer_et_reorganiser.R
│
├── 01_Donnees/              # Collecte et intégration des données
│   ├── collecte_donnees_publiques.R
│   ├── collecte_temperature.R
│   ├── combinaison_donnees.R
│   ├── calendrier_francais.R
│   └── lecture_donnees_RTE.R
│
├── 02_Analyse/              # Analyses exploratoires
│   ├── analyse_exploratoire_avancee.R
│   ├── correlations_detaillees.R
│   ├── analyse_saisonnalite.R
│   ├── detection_anomalies.R
│   ├── analyse_patterns_temporels.R
│   └── visualisations_creatives.R
│
├── 03_Modelisation/          # Modèles de séries temporelles
│   ├── modeles_series_temporelles.R
│   └── application_donnees_reelles.R
│
├── 04_Validation/            # Validation des modèles
│   ├── validation_croisee.R
│   ├── tests_robustesse.R
│   ├── validation_previsions.R
│   ├── comparaison_modeles_avancee.R
│   └── executer_tous_validation.R
│
├── 05_Prevision/             # Prévisions multi-horizons
│   ├── previsions_multi_horizons.R
│   ├── analyse_scenarios.R
│   ├── intervalles_confiance.R
│   ├── evaluation_previsions.R
│   └── executer_tous_prevision.R
│
├── 06_Dashboard/             # Dashboard Shiny
│   ├── app.R
│   └── lancer_dashboard.R
│
├── 07_Rapport/               # Rapports LaTeX
│   ├── rapport.Rmd
│   ├── INTERPRETATION_RESULTATS.tex
│   └── COMPARAISON_ANCIENS_NOUVEAUX.tex
│
├── data/                     # Données (voir .gitignore)
│   ├── dataset_complet.csv   # Dataset final (non versionné)
│   └── resultats_nouveaux/   # Résultats (non versionnés)
│
├── figures/                  # Graphiques générés (non versionnés)
├── logs/                     # Logs d'exécution (non versionnés)
│
├── README.md                 # Ce fichier
├── LICENSE                   # Licence MIT
├── .gitignore               # Fichiers à ignorer par Git
└── GUIDE_COMPLET_A_Z.md     # Guide d'utilisation complet
```

## 🚀 Installation et utilisation

### Prérequis

```r
# Installer les packages nécessaires
install.packages(c(
  "tidyverse",      # Manipulation de données
  "forecast",       # Modèles de séries temporelles
  "fpp3",           # Forecasting principles
  "tseries",        # Tests statistiques
  "urca",           # Tests de stationnarité
  "zoo",            # Objets temporels
  "lubridate",      # Manipulation de dates
  "shiny",          # Dashboard interactif
  "plotly",         # Graphiques interactifs
  "DT"              # Tableaux interactifs
))
```

### Démarrage rapide

```r
# 1. Cloner le repository
git clone https://github.com/votre-username/projet-energie-france.git
cd projet-energie-france/R_VERSION

# 2. Exécuter le pipeline complet
source("EXECUTER_TOUT.R")

# 3. Lancer le dashboard
source("06_Dashboard/lancer_dashboard.R")
```

### Exécution étape par étape

```r
# 1. Collecte des données
source("01_Donnees/combinaison_donnees.R")

# 2. Analyses exploratoires
source("02_Analyse/analyse_exploratoire_avancee.R")

# 3. Modélisation
source("03_Modelisation/application_donnees_reelles.R")

# 4. Validation
source("04_Validation/executer_tous_validation.R")

# 5. Prévisions
source("05_Prevision/executer_tous_prevision.R")
```

## 📈 Résultats

### Performance des modèles

| Modèle | RMSE (MW) | MAPE (%) | R² | Directional Accuracy |
|--------|-----------|----------|-----|---------------------|
| **ETS** | 7,231 | 12.79 | -0.264 | 20-44% |
| ARIMA | 7,399 | 13.01 | -0.323 | - |
| TBATS | 7,581 | 13.13 | -0.389 | - |

### Insights clés

- **Saisonnalité forte** : Patterns journaliers, hebdomadaires et annuels identifiés
- **Impact température** : Corrélation significative avec la consommation
- **Effets calendrier** : Weekends et jours fériés réduisent la consommation
- **Tendances** : Évolution de la consommation sur 13 ans (2012-2025)

## 🎨 Dashboard interactif

Le dashboard Shiny permet de :
- Visualiser les données historiques
- Comparer les modèles en temps réel
- Générer des prévisions interactives
- Analyser les scénarios
- Exporter les résultats

```r
# Lancer le dashboard
source("06_Dashboard/lancer_dashboard.R")
# Ouvrir http://localhost:3838
```

## 📚 Documentation

- [Guide complet A-Z](GUIDE_COMPLET_A_Z.md) - Guide d'utilisation détaillé
- [Guide d'amélioration](GUIDE_AMELIORATION_RESULTATS.tex) - Stratégies pour améliorer les résultats
- [Interprétation des résultats](INTERPRETATION_RESULTATS.tex) - Analyse détaillée des performances
- [Comparaison anciens/nouveaux résultats](COMPARAISON_ANCIENS_NOUVEAUX.tex) - Évolution du projet

## 🔧 Technologies utilisées

- **R** : Langage principal
- **Tidyverse** : Manipulation de données (dplyr, ggplot2, lubridate)
- **forecast** : Modèles de séries temporelles (ARIMA, ETS, TBATS)
- **Shiny** : Dashboard interactif
- **LaTeX** : Rapports professionnels

## 📝 Auteur

**Yahya Rahil**
- 📧 Email: yahya.rahil@etu.u-bordeaux.fr
- 🔗 LinkedIn: [yahya-rahil](https://linkedin.com/in/yahya-rahil)
- 💻 GitHub: [yahya-rahil](https://github.com/yahya-rahil)

## 📄 License

Ce projet est sous licence MIT. Voir le fichier [LICENSE](LICENSE) pour plus de détails.

## 🙏 Remerciements

- **RTE** (Réseau de Transport d'Électricité) pour les données de consommation
- **INSEE** pour les données macroéconomiques
- **Open-Meteo** pour les données météorologiques
- **data.gouv.fr** pour l'accès aux données publiques françaises

## 📊 Statistiques du projet

- **Lignes de code** : ~5,000+
- **Fichiers R** : 20+
- **Données collectées** : 1.1M+ observations
- **Modèles testés** : 4+
- **Métriques calculées** : 10+

## 🚧 Notes importantes

### Données non versionnées

Les fichiers suivants ne sont **pas** versionnés dans Git (trop volumineux) :
- `data/dataset_complet.csv` (~1.1M lignes)
- `data/RTE/*.xls` (fichiers Excel volumineux)
- `data/resultats_nouveaux/**/*.csv` (résultats générés)
- `figures/**/*.png` (graphiques générés)
- `logs/*.log` (logs d'exécution)

Pour obtenir ces fichiers, exécutez les scripts de collecte et d'analyse.

### Structure des données

Le dataset final (`dataset_complet.csv`) contient :
- **Date** : Horodatage horaire
- **Consommation** : Consommation électrique en MW
- **Temperature** : Température moyenne en °C
- **Variables économiques** : PIB, chômage, inflation
- **Variables calendrier** : Jour de semaine, mois, fériés, etc.

---

⭐ Si ce projet vous a été utile, n'hésitez pas à lui donner une étoile !

