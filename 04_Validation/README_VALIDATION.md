> **Document historique.** Les anciens scores et commandes ne décrivent plus le pipeline courant. Consulter le README à la racine et `docs/resultats_corriges/RAPPORT.md`.

# 📊 VALIDATION ET TESTS DES MODÈLES

Ce dossier contient les scripts de validation et de tests de robustesse pour les modèles de prévision.

## 📁 Scripts Disponibles

### 1. `validation_croisee.R`
**Validation croisée temporelle** pour évaluer la robustesse des modèles.

**Fonctionnalités :**
- ✅ Validation croisée temporelle (Time Series Cross-Validation)
- ✅ Validation croisée par blocs
- ✅ Évaluation sur plusieurs périodes
- ✅ Graphiques de comparaison

**Exécution :**
```r
source("04_Validation/validation_croisee.R")
```

**Fichiers générés :**
- `figures/validation_croisee.png`
- `data/validation_croisee_temporelle.csv`
- `data/validation_croisee_blocs.csv`

---

### 2. `tests_robustesse.R`
**Tests de robustesse** face aux variations de données.

**Fonctionnalités :**
- ✅ Test de robustesse aux outliers
- ✅ Test de robustesse aux données manquantes
- ✅ Test de robustesse à la taille d'échantillon
- ✅ Analyse de dégradation des performances

**Exécution :**
```r
source("04_Validation/tests_robustesse.R")
```

**Fichiers générés :**
- `figures/robustesse_taille.png`
- `data/robustesse_outliers.csv`
- `data/robustesse_manquantes.csv`
- `data/robustesse_taille.csv`

---

### 3. `validation_previsions.R`
**Validation détaillée des prévisions** avec métriques avancées.

**Fonctionnalités :**
- ✅ Validation par horizon de prévision (1h, 6h, 12h, 24h, 48h, 72h)
- ✅ Validation des intervalles de confiance
- ✅ Analyse des erreurs de prévision
- ✅ Métriques avancées (RMSE, MAE, MAPE, R², MASE, sMAPE)

**Exécution :**
```r
source("04_Validation/validation_previsions.R")
```

**Fichiers générés :**
- `figures/validation_par_horizon.png`
- `figures/erreurs_*.png` (un par modèle)
- `data/validation_par_horizon.csv`
- `data/validation_intervalles.csv`
- `data/analyse_erreurs.csv`

---

### 4. `comparaison_modeles_avancee.R`
**Comparaison approfondie** de tous les modèles.

**Fonctionnalités :**
- ✅ Ajustement de tous les modèles (ARIMA, ETS, TBATS, STL+ARIMA, Naive, Seasonal Naive)
- ✅ Calcul de toutes les métriques (RMSE, MAE, MAPE, R², MASE, sMAPE, AIC, BIC)
- ✅ Classement des modèles
- ✅ Graphiques de comparaison multi-métriques

**Exécution :**
```r
source("04_Validation/comparaison_modeles_avancee.R")
```

**Fichiers générés :**
- `figures/comparaison_modeles_complete.png`
- `figures/comparaison_multimetriques.png`
- `data/comparaison_modeles_finale.csv`

---

## 🚀 Exécution Complète

### Option 1 : Exécuter tous les scripts en une fois (RECOMMANDÉ)

```r
# Depuis le dossier R_VERSION/
setwd("/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION")

# Exécuter tous les scripts avec sauvegarde automatique des logs
source("04_Validation/executer_tous_validation.R")
```

### Option 2 : Exécuter chaque script individuellement

```r
# Depuis le dossier R_VERSION/
setwd("/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION")

# 1. Validation croisée (sauvegarde automatique dans logs/)
source("04_Validation/validation_croisee.R")

# 2. Tests de robustesse (sauvegarde automatique dans logs/)
source("04_Validation/tests_robustesse.R")

# 3. Validation des prévisions (sauvegarde automatique dans logs/)
source("04_Validation/validation_previsions.R")

# 4. Comparaison avancée (sauvegarde automatique dans logs/)
source("04_Validation/comparaison_modeles_avancee.R")
```

### 📝 Sauvegarde Automatique des Logs

**Tous les scripts sauvegardent automatiquement leur sortie dans le dossier `logs/`** :
- Chaque exécution crée un fichier de log avec timestamp
- Format : `logs/nom_script_YYYYMMDD_HHMMSS.log`
- Les logs contiennent toute la sortie console (messages, résultats, erreurs)

**Exemple de fichiers de logs créés :**
- `logs/validation_croisee_20240115_143022.log`
- `logs/tests_robustesse_20240115_143145.log`
- `logs/validation_previsions_20240115_143310.log`
- `logs/comparaison_modeles_avancee_20240115_143455.log`
- `logs/execution_complete_validation_20240115_143000.log` (si vous utilisez le script maître)

---

## 📊 Métriques Utilisées

### Métriques de Base
- **RMSE** (Root Mean Squared Error) : Erreur quadratique moyenne
- **MAE** (Mean Absolute Error) : Erreur absolue moyenne
- **MAPE** (Mean Absolute Percentage Error) : Erreur absolue en pourcentage

### Métriques Avancées
- **R²** (Coefficient de détermination) : Qualité de l'ajustement
- **MASE** (Mean Absolute Scaled Error) : Erreur normalisée par rapport à la méthode naïve
- **sMAPE** (Symmetric MAPE) : MAPE symétrique
- **AIC/BIC** : Critères d'information pour la sélection de modèles

---

## 📈 Interprétation des Résultats

### Validation Croisée
- **RMSE faible** = Meilleure précision
- **Écart-type faible** = Modèle stable sur différentes périodes

### Tests de Robustesse
- **Dégradation faible** = Modèle robuste aux variations
- **Couverture des intervalles** ≈ 95% = Intervalles de confiance fiables

### Validation par Horizon
- **RMSE croissant avec l'horizon** = Normal (prévisions plus difficiles à long terme)
- **MAPE < 10%** = Excellente précision

### Comparaison des Modèles
- **Meilleur score global** = Modèle recommandé
- **R² proche de 1** = Excellent ajustement

---

## ⚠️ Notes Importantes

1. **Temps d'exécution** : Les scripts peuvent prendre plusieurs minutes selon la taille des données
2. **Échantillonnage** : Les scripts échantillonnent automatiquement si les données sont trop volumineuses (> 50,000 observations)
3. **Gestion des erreurs** : Les scripts continuent même si certains modèles échouent
4. **Dépendances** : Tous les packages nécessaires sont installés automatiquement

---

## 📚 Prochaines Étapes

Après la validation, vous pouvez :
1. ✅ Passer aux **prévisions avancées** (`05_Prevision/`)
2. ✅ Créer un **dashboard interactif** (`06_Dashboard/`)
3. ✅ Générer un **rapport final** (`07_Rapport/`)

