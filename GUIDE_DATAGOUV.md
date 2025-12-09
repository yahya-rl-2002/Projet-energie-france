# 📊 GUIDE : DONNÉES data.gouv.fr

## ✅ COLLECTE AUTOMATIQUE RÉUSSIE

Le script `collecte_datagouv.R` a téléchargé automatiquement **17 datasets** depuis data.gouv.fr !

---

## 📁 FICHIERS TÉLÉCHARGÉS

### 📂 Emplacement
```
PROJET_ENERGIE_FRANCE/R_VERSION/data/data_gouv/
```

### 📊 Datasets téléchargés (17 fichiers CSV)

#### 1. **Consommation Électrique** ⚡
- ✅ `Consommation__lectrique_annuelle_des_appareils_dom_1.csv` (596 KB, 8806 lignes)
  - Consommation annuelle des appareils domestiques
- ✅ `Consommation_et_thermosensibilit___lectriques_annu_1.csv` (89 KB, 587 lignes)
  - Consommation et thermosensibilité électriques (Orléans Métropole)
- ✅ `Sobri_t__de_la_consommation__lectrique_tertiaire_1.csv` (389 B)
  - Sobriété de la consommation électrique tertiaire

#### 2. **Consommation Énergétique** 🔋
- ✅ `Consommation__nerg_tique_2011_2023_par_commune_1.csv` (326 KB, 1496 lignes)
  - **TRÈS UTILE** : Consommation énergétique par commune (2011-2023)
- ✅ `Consommation__nerg_tique_des_b_timents_tertiaires__1.csv` (1.9 MB, 25748 lignes)
  - **TRÈS UTILE** : Consommation énergétique des bâtiments tertiaires par commune

#### 3. **Émissions CO2** 🌍
- ✅ `_missions_de_CO2_consolid_es_par_pays_du_groupe_ED_1.csv` (8.2 MB, 92 lignes)
  - **TRÈS UTILE** : Émissions CO2 consolidées par pays du groupe EDF
- ✅ `Bilan_carbone_du_D_partement_des_Alpes_de_Haute_Pr_1.csv` (2.7 KB, 130 lignes)
  - Bilan carbone départemental
- ✅ `Declaration_vehicules___faibles__missions_de_CO2_1.csv` (1.5 KB)
  - Déclaration véhicules à faibles émissions

#### 4. **Énergies Renouvelables** 🌱
- ✅ `Panorama_des__nergies_renouvelables_1.csv` (12 KB, 221 lignes)
  - Panorama des énergies renouvelables
- ✅ `Production_d__nergies_renouvelables_1.csv` (804 B, 10 lignes)
  - Production d'énergies renouvelables
- ✅ `Energies___Part_des__nergies_renouvelables_dans_le_1.csv` (310 B, 13 lignes)
  - Part des énergies renouvelables dans le réseau de chaleur

#### 5. **Transition Énergétique** 🔄
- ✅ `R_pertoire_des_actions_solutions_de_la_feuille_de__1.csv` (212 KB, 453 lignes)
  - Répertoire des actions/solutions de transition écologique et énergétique
- ✅ `Id_es_fortes_de_la_feuille_de_route_transition__co_1.csv` (18 KB, 110 lignes)
  - Idées fortes de la feuille de route transition
- ✅ `Th_mes_de_la_feuille_de_route_transition__cologiqu_1.csv` (3.2 KB, 10 lignes)
  - Thèmes de la feuille de route transition

#### 6. **Efficacité Énergétique** ⚙️
- ✅ `Actions_d_Efficacit___nerg_tique_1.csv` (25 KB, 522 lignes)
  - Actions d'efficacité énergétique

#### 7. **Conseils** 💡
- ✅ `Conseils_pour_r_duire_sa_consommation__nerg_tique_1.csv` (826 B, 5 lignes)
  - Conseils pour réduire sa consommation énergétique

---

## 🚀 UTILISATION

### Option 1 : Relancer la collecte

```r
# Aller dans le dossier du projet
setwd("/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION")

# Charger le script
source("01_Donnees/collecte_datagouv.R")

# Collecter les données
collecte_datagouv_complete()
```

### Option 2 : Lire les fichiers déjà téléchargés

```r
# Charger le script
source("01_Donnees/collecte_datagouv.R")

# Lire tous les fichiers
donnees <- lire_fichiers_datagouv()

# Accéder à un dataset spécifique
donnees[["Consommation__nerg_tique_2011_2023_par_commune_1.csv"]]
```

### Option 3 : Lire un fichier spécifique

```r
library(tidyverse)

# Lire consommation énergétique par commune
df <- read.csv2(
  "data/data_gouv/Consommation__nerg_tique_2011_2023_par_commune_1.csv",
  encoding = "UTF-8",
  check.names = FALSE
)

# Explorer
head(df)
str(df)
summary(df)
```

---

## 📈 DATASETS LES PLUS UTILES POUR VOTRE PROJET

### ⭐ Priorité 1 : À utiliser absolument

1. **`Consommation__nerg_tique_2011_2023_par_commune_1.csv`**
   - **Pourquoi** : Données de consommation énergétique par commune sur 12 ans
   - **Utilisation** : Enrichir vos données avec des données communales
   - **Colonnes** : 48 colonnes (années 2011-2023, différents types d'énergie)

2. **`_missions_de_CO2_consolid_es_par_pays_du_groupe_ED_1.csv`**
   - **Pourquoi** : Émissions CO2 du groupe EDF (très pertinent pour l'énergie)
   - **Utilisation** : Analyser la corrélation consommation/émissions
   - **Colonnes** : 12 colonnes avec données par pays et année

3. **`Consommation__nerg_tique_des_b_timents_tertiaires__1.csv`**
   - **Pourquoi** : 25 748 lignes de données sur les bâtiments tertiaires
   - **Utilisation** : Analyser la consommation par secteur
   - **Colonnes** : 2 colonnes (commune, consommation)

### ⭐ Priorité 2 : Très utiles

4. **`Consommation_et_thermosensibilit___lectriques_annu_1.csv`**
   - **Pourquoi** : Données de thermosensibilité (impact température)
   - **Utilisation** : Corréler avec données météo
   - **Colonnes** : 44 colonnes

5. **`Panorama_des__nergies_renouvelables_1.csv`**
   - **Pourquoi** : Données sur les énergies renouvelables
   - **Utilisation** : Analyser le mix énergétique
   - **Colonnes** : 6 colonnes

---

## 🔧 INTÉGRATION DANS VOTRE PROJET

### Étape 1 : Modifier `combinaison_donnees.R`

Ajoutez une fonction pour charger les données data.gouv.fr :

```r
charger_donnees_datagouv <- function() {
  cat("📊 Chargement données data.gouv.fr...\n")
  
  # Lire consommation énergétique par commune
  tryCatch({
    df_commune <- read.csv2(
      "data/data_gouv/Consommation__nerg_tique_2011_2023_par_commune_1.csv",
      encoding = "UTF-8",
      check.names = FALSE
    )
    cat("  ✅ Consommation par commune chargée\n")
    return(df_commune)
  }, error = function(e) {
    cat("  ⚠️ Erreur:", e$message, "\n")
    return(NULL)
  })
}
```

### Étape 2 : Combiner avec vos données

Dans `combinaison_donnees.R`, ajoutez :

```r
# Charger données data.gouv.fr
donnees_datagouv <- charger_donnees_datagouv()

# Combiner avec votre dataset principal
if (!is.null(donnees_datagouv)) {
  # Logique de combinaison selon vos besoins
  # ...
}
```

---

## 📊 STATISTIQUES

- **Total datasets téléchargés** : 17
- **Total fichiers** : 30+ (CSV + JSON)
- **Taille totale** : ~25 MB
- **Lignes totales** : ~40 000+ lignes de données
- **Période couverte** : 2011-2023 (selon datasets)

---

## 🔄 RELANCER LA COLLECTE

Pour télécharger de nouveaux datasets ou mettre à jour :

```r
# Relancer la collecte complète
source("01_Donnees/collecte_datagouv.R")
collecte_datagouv_complete()
```

Le script évite les doublons (ne télécharge pas les datasets déjà présents).

---

## 💡 PROCHAINES ÉTAPES

1. ✅ **Fait** : Données téléchargées depuis data.gouv.fr
2. ⏭️ **À faire** : Intégrer dans `combinaison_donnees.R`
3. ⏭️ **À faire** : Analyser les corrélations avec vos données
4. ⏭️ **À faire** : Utiliser pour améliorer vos modèles

---

## 📝 NOTES

- Les fichiers JSON sont également téléchargés mais non lus automatiquement
- Certains fichiers peuvent nécessiter un nettoyage (encodage, format)
- Les noms de fichiers sont automatiquement nettoyés (caractères spéciaux remplacés)
- Le script crée un résumé dans `resume_fichiers.csv`

---

## 🆘 PROBLÈMES ?

Si un fichier ne se lit pas correctement :

```r
# Essayer différents encodages
df1 <- read.csv2(fichier, encoding = "UTF-8")
df2 <- read.csv2(fichier, encoding = "latin-1")
df3 <- read.csv(fichier, encoding = "UTF-8")

# Ou utiliser data.table
library(data.table)
df4 <- fread(fichier, encoding = "Latin-1")
```

---

**✅ Collecte terminée avec succès !**

