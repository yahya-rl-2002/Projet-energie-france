> **Document historique.** Les anciens scores et commandes ne décrivent plus le pipeline courant. Consulter le README à la racine et `docs/resultats_corriges/RAPPORT.md`.

# 📊 Guide d'Interprétation des Résultats

## 📄 Document LaTeX créé

Un document LaTeX complet a été créé : `INTERPRETATION_RESULTATS.tex`

Ce document contient :
- ✅ Interprétation détaillée de tous les résultats
- ✅ Formules mathématiques complètes
- ✅ Tableaux formatés
- ✅ Analyse critique des performances
- ✅ Recommandations d'amélioration

## 🔨 Compilation du document

### Option 1 : Script automatique

```bash
./compiler_interpretation.sh
```

### Option 2 : Compilation manuelle

```bash
pdflatex INTERPRETATION_RESULTATS.tex
pdflatex INTERPRETATION_RESULTATS.tex  # Deuxième passe pour les références
```

### Option 3 : Avec R (si TinyTeX installé)

```r
tinytex::pdflatex("INTERPRETATION_RESULTATS.tex")
```

## 📋 Contenu du document

### 1. Introduction
- Caractéristiques du dataset
- Statistiques descriptives

### 2. Comparaison des Modèles
- Tableau comparatif (ETS, ARIMA, TBATS)
- Interprétation du RMSE, MAPE, R²

### 3. Évaluation Multi-Horizons
- Performance par horizon (1h, 6h, 12h, 24h, 48h, 72h)
- Analyse du Theil's U
- Interprétation des métriques

### 4. Directional Accuracy
- Capacité à prédire la direction
- Analyse critique

### 5. Couverture des Intervalles
- Analyse des intervalles de confiance
- Calibration des prévisions

### 6. Conclusion et Recommandations
- Synthèse des performances
- Points forts et faibles
- Recommandations d'amélioration

## 📊 Résultats clés interprétés

### Meilleur modèle : ETS
- **RMSE** : 7,231 MW (12.4% de la moyenne)
- **MAPE** : 12.79% (acceptable)
- **R²** : -0.264 (préoccupant)

### Performance par horizon
- **1h** : MAPE = 0.19% (excellent)
- **6h-72h** : MAPE = 11-12% (acceptable)

### Points forts
✅ Prévisions à très court terme excellentes
✅ Stabilité sur différents horizons
✅ Theil's U < 0.1 (bonne qualité)

### Points faibles
❌ R² négatif (modèle pire qu'une moyenne simple)
❌ Directional Accuracy faible (20-44%)
❌ MASE > 1 (pire qu'une prévision naïve saisonnière)

## 🔍 Formules incluses

Le document contient toutes les formules mathématiques :
- RMSE, MAE, MAPE, MASE
- R², Theil's U
- Directional Accuracy
- Couverture des intervalles

## 📈 Recommandations

Le document inclut des recommandations détaillées pour :
1. Améliorer les modèles (hybrides, ML, variables exogènes)
2. Enrichir les données (compléter NA, ajouter variables)
3. Améliorer la validation (cross-validation, robustesse)

## 🎯 Utilisation

1. Compilez le document LaTeX
2. Consultez le PDF généré
3. Utilisez les interprétations pour :
   - Présenter les résultats
   - Identifier les améliorations
   - Documenter le projet

## 📝 Notes

- Le document est en français
- Toutes les formules sont en notation mathématique standard
- Les tableaux sont formatés avec `booktabs`
- Les références croisées sont automatiques


