# 🔮 PRÉVISIONS AVANCÉES

Ce dossier contient les scripts pour générer et évaluer des prévisions avancées.

## 📁 Scripts Disponibles

### 1. `previsions_multi_horizons.R`
**Prévisions pour différents horizons temporels**

**Fonctionnalités :**
- ✅ Prévisions pour 1h, 6h, 12h, 24h, 48h, 72h, 1 semaine, 1 mois
- ✅ Utilisation automatique du meilleur modèle identifié
- ✅ Graphiques de prévisions par horizon
- ✅ Export CSV par horizon

**Exécution :**
```r
source("05_Prevision/previsions_multi_horizons.R")
```

**Fichiers générés :**
- `figures/previsions_multi_horizons.png`
- `data/previsions_multi_horizons.csv`
- `data/previsions_h*.csv` (un fichier par horizon)

---

### 2. `analyse_scenarios.R`
**Analyse de scénarios (optimiste, réaliste, pessimiste)**

**Fonctionnalités :**
- ✅ Scénario optimiste (-5% par rapport à la tendance)
- ✅ Scénario réaliste (tendance actuelle)
- ✅ Scénario pessimiste (+5% par rapport à la tendance)
- ✅ Comparaison visuelle des scénarios
- ✅ Statistiques par scénario

**Exécution :**
```r
source("05_Prevision/analyse_scenarios.R")
```

**Fichiers générés :**
- `figures/previsions_scenarios.png`
- `figures/comparaison_scenarios.png`
- `data/previsions_scenarios.csv`
- `data/statistiques_scenarios.csv`

---

### 3. `intervalles_confiance.R`
**Analyse détaillée des intervalles de confiance**

**Fonctionnalités :**
- ✅ Intervalles de confiance à 50%, 80%, 90%, 95%, 99%
- ✅ Analyse de la largeur des intervalles
- ✅ Visualisation des intervalles multiples
- ✅ Export des intervalles

**Exécution :**
```r
source("05_Prevision/intervalles_confiance.R")
```

**Fichiers générés :**
- `figures/intervalles_confiance_multiples.png`
- `figures/largeur_intervalles.png`
- `data/previsions_intervalles_confiance.csv`

---

### 4. `evaluation_previsions.R`
**Évaluation détaillée de la qualité des prévisions**

**Fonctionnalités :**
- ✅ Métriques complètes (RMSE, MAE, MAPE, R², MASE, sMAPE, Theil's U)
- ✅ Évaluation par horizon
- ✅ Couverture des intervalles de confiance
- ✅ Directional Accuracy
- ✅ Graphiques d'évaluation

**Exécution :**
```r
source("05_Prevision/evaluation_previsions.R")
```

**Fichiers générés :**
- `figures/evaluation_previsions.png`
- `data/evaluation_previsions.csv`

---

## 🚀 Exécution Complète

Pour exécuter tous les scripts de prévision :

```r
# Depuis le dossier R_VERSION/
setwd("/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION")

# 1. Prévisions multi-horizons
source("05_Prevision/previsions_multi_horizons.R")

# 2. Analyse de scénarios
source("05_Prevision/analyse_scenarios.R")

# 3. Intervalles de confiance
source("05_Prevision/intervalles_confiance.R")

# 4. Évaluation des prévisions
source("05_Prevision/evaluation_previsions.R")
```

---

## 📊 Métriques Utilisées

### Métriques de Base
- **RMSE** (Root Mean Squared Error) : Erreur quadratique moyenne
- **MAE** (Mean Absolute Error) : Erreur absolue moyenne
- **MAPE** (Mean Absolute Percentage Error) : Erreur absolue en pourcentage

### Métriques Avancées
- **R²** (Coefficient de détermination) : Qualité de l'ajustement
- **MASE** (Mean Absolute Scaled Error) : Erreur normalisée
- **sMAPE** (Symmetric MAPE) : MAPE symétrique
- **Theil's U** : Ratio d'erreur de Theil
- **Directional Accuracy** : Précision directionnelle
- **Couverture** : Pourcentage de valeurs réelles dans les intervalles

---

## 📝 Sauvegarde Automatique des Logs

**Tous les scripts sauvegardent automatiquement leur sortie dans le dossier `logs/`** :
- Chaque exécution crée un fichier de log avec timestamp
- Format : `logs/nom_script_YYYYMMDD_HHMMSS.log`
- Les logs contiennent toute la sortie console (messages, résultats, erreurs)

**Exemple de fichiers de logs créés :**
- `logs/previsions_multi_horizons_20240115_150000.log`
- `logs/analyse_scenarios_20240115_150500.log`
- `logs/intervalles_confiance_20240115_151000.log`
- `logs/evaluation_previsions_20240115_151500.log`

---

## 📈 Interprétation des Résultats

### Prévisions Multi-Horizons
- **RMSE croissant avec l'horizon** = Normal (prévisions plus difficiles à long terme)
- **MAPE < 10%** = Excellente précision
- **MAPE 10-20%** = Bonne précision
- **MAPE > 20%** = Précision modérée

### Scénarios
- **Scénario optimiste** = Consommation en baisse (meilleur cas)
- **Scénario réaliste** = Tendance actuelle maintenue
- **Scénario pessimiste** = Consommation en hausse (pire cas)

### Intervalles de Confiance
- **Couverture ≈ 95%** = Intervalles fiables
- **Largeur croissante** = Incertitude croissante avec l'horizon
- **Largeur constante** = Modèle stable

### Évaluation
- **R² proche de 1** = Excellent ajustement
- **MASE < 1** = Meilleur que la méthode naïve
- **Directional Accuracy > 50%** = Modèle prédit correctement la direction

---

## ⚠️ Notes Importantes

1. **Modèle utilisé** : Les scripts utilisent automatiquement le meilleur modèle identifié dans `data/comparaison_modeles_finale.csv` (TBATS par défaut)
2. **Temps d'exécution** : Les scripts peuvent prendre plusieurs minutes selon la taille des données
3. **Échantillonnage** : Les scripts échantillonnent automatiquement si les données sont trop volumineuses (> 50,000 observations)
4. **Gestion des erreurs** : Les scripts continuent même si certains calculs échouent

---

## 📚 Prochaines Étapes

Après les prévisions, vous pouvez :
1. ✅ Créer un **dashboard interactif** (`06_Dashboard/`)
2. ✅ Générer un **rapport final** (`07_Rapport/`)

