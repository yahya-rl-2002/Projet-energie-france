# 📊 GUIDE : UTILISER LES DONNÉES RTE

## ✅ CE QUE VOUS AVEZ

Vous avez téléchargé **26 fichiers RTE** dans le dossier `new data/` :

### 📁 Fichiers Annuels Définitifs (2012-2023)
- `eCO2mix_RTE_Annuel-Definitif_2012.xls` à `2023.xls`
- **12 fichiers** avec données historiques complètes
- Chaque fichier : ~4.4-5.0 MB
- **Contenu** : Consommation, production par filière, échanges transfrontaliers

### 📁 Fichiers En Cours
- `eCO2mix_RTE_En-cours-Consolide.xls` : Données consolidées de l'année en cours
- `eCO2mix_RTE_En-cours-TR.xls` : Données temps réel

### 📁 Calendriers TEMPO (2014-2025)
- `eCO2mix_RTE_tempo_2014-2015.xls` à `2025-2026.xls`
- **12 fichiers** pour identifier les jours spéciaux
- Utile pour la tarification et l'analyse

---

## 🚀 COMMENT UTILISER

### Étape 1 : Installer les Packages Nécessaires

```r
# Installer si nécessaire
install.packages(c("readxl", "tidyverse", "lubridate"))

# Charger
library(readxl)
library(tidyverse)
library(lubridate)
```

### Étape 2 : Lire Toutes les Données RTE

```r
# Aller dans le dossier du projet
setwd("/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION/01_Donnees")

# Charger le script
source("lecture_donnees_RTE.R")

# Lire toutes les données
donnees_RTE <- lire_toutes_donnees_RTE()
```

**Résultat** :
- `data/RTE/RTE_annuels_combines.csv` : Toutes les données annuelles combinées
- `data/RTE/RTE_en_cours_combines.csv` : Données en cours
- `data/RTE/RTE_tempo_combines.csv` : Calendriers TEMPO

---

## 📊 STRUCTURE DES DONNÉES

### Données Annuelles

Chaque fichier annuel contient généralement :

- **Date/Heure** : Horodatage des données
- **Consommation** : Consommation électrique (MW)
- **Production par filière** :
  - Nucléaire
  - Éolien (terrestre + offshore)
  - Solaire
  - Hydraulique
  - Gaz
  - Charbon
  - Autres
- **Échanges transfrontaliers** : Import/Export avec pays voisins
- **Taux de CO2** : Émissions par MWh

### Calendriers TEMPO

Contiennent :
- **Date** : Date du jour
- **Couleur TEMPO** : Bleu, Blanc, Rouge
  - **Bleu** : Jour de faible consommation
  - **Blanc** : Jour normal
  - **Rouge** : Jour de forte consommation
- **Impact** : Sur la tarification et la consommation

---

## 🔗 INTÉGRER AVEC VOS DONNÉES

### Option 1 : Utiliser dans combinaison_donnees.R

Modifier `combinaison_donnees.R` pour inclure les données RTE :

```r
# Dans combiner_toutes_donnees()

# Charger données RTE annuelles
if (file.exists("data/RTE/RTE_annuels_combines.csv")) {
  rte_annuels <- read.csv("data/RTE/RTE_annuels_combines.csv")
  
  # Joindre avec vos données
  df_complet <- df_complet %>%
    left_join(rte_annuels, by = "Date")
  
  cat("✅ Données RTE intégrées\n")
}
```

### Option 2 : Créer un Nouveau Script

Créer `integration_RTE.R` pour combiner tout :

```r
# Charger vos données
source("combinaison_donnees.R")
dataset_base <- combiner_toutes_donnees()

# Charger données RTE
rte_annuels <- read.csv("data/RTE/RTE_annuels_combines.csv")

# Combiner
dataset_final <- dataset_base %>%
  left_join(rte_annuels, by = "Date")

# Sauvegarder
write.csv(dataset_final, "data/dataset_complet_avec_RTE.csv", row.names = FALSE)
```

---

## 📈 UTILISER DANS LES MODÈLES

### Variables RTE Disponibles

Une fois intégrées, vous aurez accès à :

1. **Production par filière** :
   - `Production_Nucleaire`
   - `Production_Eolien`
   - `Production_Solaire`
   - `Production_Hydraulique`
   - `Production_Gaz`
   - etc.

2. **Échanges transfrontaliers** :
   - `Echanges_Import`
   - `Echanges_Export`

3. **Taux de CO2** :
   - `Taux_CO2`

### Utilisation dans SARIMAX

```r
# Variables exogènes avec données RTE
variables_exogenes <- cbind(
  Temperature = df_complet$Temperature,
  Production_Nucleaire = df_complet$Production_Nucleaire,
  Production_Eolien = df_complet$Production_Eolien,
  EstWeekend = df_complet$EstWeekend
)

# Ajuster SARIMAX avec variables RTE
modele_sarimax <- Arima(consommation_ts,
                        order = c(1, 1, 1),
                        seasonal = c(1, 1, 1),
                        xreg = variables_exogenes)
```

---

## 🎯 AVANTAGES DES DONNÉES RTE

### 1. Validation de Vos Données
- Comparer vos données (defi1, defi2, defi3) avec les données officielles RTE
- Vérifier la cohérence

### 2. Enrichissement
- Ajouter production par filière
- Ajouter échanges transfrontaliers
- Ajouter taux de CO2

### 3. Amélioration des Prévisions
- Plus de variables = meilleures prévisions
- Comprendre l'impact de chaque source d'énergie

### 4. Analyse Avancée
- Analyser le mix énergétique
- Analyser l'impact des énergies renouvelables
- Analyser les échanges avec pays voisins

---

## ⚠️ NOTES IMPORTANTES

### Format des Fichiers
- Les fichiers sont en format `.xls` (Excel)
- Le script essaie de les lire comme Excel, puis comme CSV si nécessaire
- Encodage : ISO-8859-1 (latin-1)

### Structure des Fichiers
- Les fichiers peuvent avoir des structures légèrement différentes selon l'année
- Le script trouve automatiquement les colonnes communes
- Certaines colonnes peuvent varier entre années

### Taille des Données
- Fichiers annuels : ~4-5 MB chacun
- Total combiné : ~50-60 MB
- Temps de lecture : 2-5 minutes

---

## 🐛 RÉSOLUTION DE PROBLÈMES

### Erreur : "Package readxl non trouvé"
```r
install.packages("readxl")
```

### Erreur : "Impossible de lire le fichier"
- Vérifier que les fichiers sont bien dans `new data/`
- Vérifier que les fichiers ne sont pas corrompus
- Essayer de lire un fichier manuellement avec Excel

### Erreur : "Colonnes différentes"
- Normal : Les fichiers peuvent avoir des structures différentes
- Le script garde seulement les colonnes communes
- Vérifier le résultat dans `data/RTE/`

---

## ✅ CHECKLIST

- [ ] Installer packages (`readxl`, `tidyverse`)
- [ ] Exécuter `lecture_donnees_RTE.R`
- [ ] Vérifier les fichiers créés dans `data/RTE/`
- [ ] Intégrer avec vos données existantes
- [ ] Utiliser dans les modèles SARIMAX

---

## 🚀 PROCHAINES ÉTAPES

1. **Lire les données RTE** : Exécuter le script
2. **Vérifier les résultats** : Ouvrir les fichiers CSV créés
3. **Intégrer** : Modifier `combinaison_donnees.R` pour inclure RTE
4. **Utiliser** : Dans vos modèles de prévision

**Bon travail ! 💪**




