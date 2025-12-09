# 📁 Structure du Projet

Ce document décrit la structure complète du projet et l'organisation des fichiers.

## 🗂️ Organisation générale

```
R_VERSION/
│
├── 00_Utilitaires/          # Scripts utilitaires et helpers
├── 01_Donnees/              # Collecte et préparation des données
├── 02_Analyse/              # Analyses exploratoires
├── 03_Modelisation/         # Modèles de séries temporelles
├── 04_Validation/           # Validation des modèles
├── 05_Prevision/             # Prévisions multi-horizons
├── 06_Dashboard/             # Dashboard Shiny
├── 07_Rapport/               # Rapports et documentation
│
├── data/                     # Données (non versionnées)
├── figures/                 # Graphiques générés (non versionnés)
├── logs/                     # Logs d'exécution (non versionnés)
│
└── Documentation/           # Fichiers de documentation
```

## 📂 Détails par dossier

### 00_Utilitaires/

Scripts utilitaires réutilisables dans tout le projet.

- `chemins_resultats.R` : Gestion des chemins vers les résultats
- `archiver_anciens_scripts.R` : Archivage des anciens scripts
- `nettoyer_et_reorganiser.R` : Nettoyage et réorganisation des fichiers

### 01_Donnees/

Collecte, nettoyage et intégration des données.

- `collecte_donnees_publiques.R` : Collecte depuis INSEE, Eurostat, Yahoo Finance
- `collecte_temperature.R` : Collecte des données météorologiques
- `collecte_temperature_rapide.R` : Version optimisée pour grandes périodes
- `combinaison_donnees.R` : **Script principal** - Combine toutes les sources
- `calendrier_francais.R` : Génération du calendrier français complet
- `lecture_donnees_RTE.R` : Lecture des fichiers RTE
- `corriger_temperature.R` : Correction des données de température

**Output principal** : `data/dataset_complet.csv`

### 02_Analyse/

Analyses exploratoires et visualisations.

- `analyse_exploratoire_avancee.R` : Analyse descriptive complète
- `correlations_detaillees.R` : Matrice de corrélations
- `analyse_saisonnalite.R` : Décomposition STL, saisonnalité
- `detection_anomalies.R` : Détection d'anomalies (IQR, Z-score)
- `analyse_patterns_temporels.R` : Patterns temporels (horaire, hebdomadaire, annuel)
- `visualisations_creatives.R` : Graphiques interactifs avec Plotly

**Outputs** : `data/resultats_nouveaux/analyses/*.csv`

### 03_Modelisation/

Implémentation des modèles de séries temporelles.

- `modeles_series_temporelles.R` : **Fonctions des modèles**
  - AR, MA, ARMA
  - ARIMA (auto)
  - SARIMA (auto)
  - SARIMAX
  - Tests de stationnarité
  - Diagnostics des résidus
- `application_donnees_reelles.R` : **Script principal** - Application sur les données

**Outputs** : Modèles ajustés, comparaison des modèles

### 04_Validation/

Validation rigoureuse des modèles.

- `validation_croisee.R` : Validation croisée temporelle
- `tests_robustesse.R` : Tests de robustesse (outliers, données manquantes)
- `validation_previsions.R` : Validation détaillée des prévisions
- `comparaison_modeles_avancee.R` : Comparaison avancée avec toutes les métriques
- `executer_tous_validation.R` : **Script maître** - Exécute tous les scripts de validation

**Outputs** : `data/resultats_nouveaux/validations/*.csv`

### 05_Prevision/

Génération de prévisions multi-horizons.

- `previsions_multi_horizons.R` : Prévisions pour différents horizons (1h, 6h, 24h, etc.)
- `analyse_scenarios.R` : Analyse de scénarios (optimiste, réaliste, pessimiste)
- `intervalles_confiance.R` : Calcul des intervalles de confiance
- `evaluation_previsions.R` : Évaluation de la qualité des prévisions
- `executer_tous_prevision.R` : **Script maître** - Exécute tous les scripts de prévision

**Outputs** : `data/resultats_nouveaux/previsions/*.csv`

### 06_Dashboard/

Dashboard interactif Shiny.

- `app.R` : **Application Shiny principale**
- `lancer_dashboard.R` : Script pour lancer le dashboard

**Usage** : `source("06_Dashboard/lancer_dashboard.R")`

### 07_Rapport/

Rapports et documentation LaTeX.

- `rapport.Rmd` : Rapport R Markdown
- `INTERPRETATION_RESULTATS.tex` : Interprétation des résultats
- `COMPARAISON_ANCIENS_NOUVEAUX.tex` : Comparaison des résultats

**Compilation** : Utiliser les scripts `compiler_*.sh`

## 📊 Fichiers de données

### Versionnés (petits fichiers)

- `data/Calendrier/calendrier_francais_complet.csv` : Calendrier français
- `data/INSEE_*.csv` : Données INSEE (PIB, chômage, inflation)
- `data/Eurostat_*.csv` : Données Eurostat

### Non versionnés (trop volumineux)

- `data/dataset_complet.csv` : **Dataset final** (~1.1M lignes, 47 variables)
- `data/RTE/*.xls` : Fichiers Excel RTE
- `data/data_gouv/*.csv` : Données data.gouv.fr
- `data/resultats_nouveaux/**/*.csv` : Tous les résultats générés

## 📈 Fichiers de résultats

Tous les résultats sont dans `data/resultats_nouveaux/` :

```
resultats_nouveaux/
├── analyses/          # Résultats des analyses exploratoires
├── modeles/          # Comparaison des modèles
├── previsions/       # Prévisions multi-horizons
└── validations/      # Résultats de validation
```

## 🎨 Fichiers de visualisation

- `figures/` : Tous les graphiques générés (PNG, HTML, etc.)

## 📝 Fichiers de documentation

À la racine du projet :

- `README.md` : **Documentation principale**
- `GUIDE_COMPLET_A_Z.md` : Guide d'utilisation complet
- `GUIDE_AMELIORATION_RESULTATS.tex` : Guide d'amélioration
- `ETAT_PROJET.md` : État actuel du projet
- `SETUP_GIT.md` : Guide de configuration Git
- `PROJECT_STRUCTURE.md` : Ce fichier

## 🔄 Workflow d'exécution

### Ordre recommandé

1. **Collecte des données** : `01_Donnees/combinaison_donnees.R`
2. **Analyses exploratoires** : Scripts dans `02_Analyse/`
3. **Modélisation** : `03_Modelisation/application_donnees_reelles.R`
4. **Validation** : `04_Validation/executer_tous_validation.R`
5. **Prévisions** : `05_Prevision/executer_tous_prevision.R`
6. **Dashboard** : `06_Dashboard/lancer_dashboard.R`

### Scripts maîtres

- `EXECUTER_TOUT.R` : Exécute tout le pipeline
- `04_Validation/executer_tous_validation.R` : Exécute toutes les validations
- `05_Prevision/executer_tous_prevision.R` : Exécute toutes les prévisions

## 🔧 Fichiers de configuration

- `.gitignore` : Fichiers à ignorer par Git
- `LICENSE` : Licence MIT
- `CONTRIBUTING.md` : Guide de contribution

## 📦 Dépendances

Tous les packages R nécessaires sont listés dans les scripts. Principaux :

- `tidyverse` : Manipulation de données
- `forecast` : Modèles de séries temporelles
- `shiny` : Dashboard interactif
- `plotly` : Graphiques interactifs

## 🚀 Pour démarrer

1. Lire `README.md`
2. Suivre `GUIDE_COMPLET_A_Z.md`
3. Exécuter `EXECUTER_TOUT.R` ou suivre étape par étape

---

**Note** : Cette structure est conçue pour être claire, modulaire et facilement extensible.

