# 🚀 GUIDE SIMPLE - REPARTIR DE ZÉRO

**Pour ceux qui se sentent perdus - Guide étape par étape très simple**

---

## 📋 ÉTAPE 1 : OUVRIRE R

### Sur Mac :
1. Ouvrir **RStudio** (ou Terminal puis taper `R`)
2. Vous voyez `>` dans la console
3. ✅ C'est bon !

---

## 📋 ÉTAPE 2 : ALLER DANS LE BON DOSSIER

```r
# Copier-coller cette ligne dans R
setwd("/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION")

# Vérifier que vous êtes au bon endroit
getwd()
# Doit afficher : "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION"
```

---

## 📋 ÉTAPE 3 : INSTALLER LES PACKAGES (UNE SEULE FOIS)

```r
# Copier-coller tout ce bloc
packages <- c("tidyverse", "forecast", "tseries", "urca", 
              "ggplot2", "lubridate", "rmarkdown", "knitr", "kableExtra")

# Installer les packages manquants
install.packages(packages[!packages %in% installed.packages()[,"Package"]])

# Attendre la fin (peut prendre 5-10 minutes)
```

**💡 Si ça demande de choisir un serveur CRAN** : Choisir **35** (France Paris 1)

---

## 📋 ÉTAPE 4 : CHARGER VOS DONNÉES (DÉFI 1, 2, 3)

```r
# Vérifier que vos fichiers existent
file.exists("../../defi1.csv")
file.exists("../../defi2.csv")
file.exists("../../defi3.csv")

# Si tous affichent TRUE, c'est bon !
```

---

## 📋 ÉTAPE 5 : COMBINER VOS DONNÉES

```r
# Charger le script de combinaison
source("01_Donnees/combinaison_donnees.R")

# Combiner toutes les données
dataset_complet <- combiner_toutes_donnees()

# Voir le résultat
head(dataset_complet)
```

**✅ Résultat attendu** : 
- "Dataset combiné créé: 225687 observations"
- Fichier créé : `01_Donnees/data/dataset_complet.csv`

---

## 📋 ÉTAPE 6 : FAIRE LA MODÉLISATION

```r
# Aller dans le dossier modélisation
setwd("03_Modelisation")

# Charger les fonctions de modélisation
source("modeles_series_temporelles.R")

# Appliquer sur vos données
source("application_donnees_reelles.R")
```

**⏱️ Temps** : 5-10 minutes (les modèles prennent du temps)

**✅ Résultat attendu** :
- Graphiques dans `figures/`
- Prévisions dans `data/previsions_24h.csv`
- Comparaison des modèles dans `data/comparaison_modeles.csv`

---

## 📋 ÉTAPE 7 : VOIR LES RÉSULTATS

```r
# Revenir au dossier principal
setwd("..")

# Voir les graphiques créés
list.files("figures")

# Voir les prévisions
previsions <- read.csv("data/previsions_24h.csv")
head(previsions)

# Voir la comparaison des modèles
comparaison <- read.csv("data/comparaison_modeles.csv")
print(comparaison)
```

---

## 📋 ÉTAPE 8 : GÉNÉRER LE RAPPORT (OPTIONNEL)

```r
# Aller dans le dossier rapport
setwd("07_Rapport")

# Charger rmarkdown
library(rmarkdown)

# Générer le HTML (plus simple que PDF)
render("rapport.Rmd", output_format = "html_document")

# Le rapport sera créé : rapport.html
# Ouvrir avec votre navigateur !
```

---

## 🎯 RÉCAPITULATIF - ORDRE DES ÉTAPES

```
1. Ouvrir R
2. setwd() → Aller dans le bon dossier
3. Installer packages (une seule fois)
4. Combiner vos données (defi1, defi2, defi3)
5. Faire la modélisation
6. Voir les résultats
7. Générer le rapport (optionnel)
```

---

## ❓ PROBLÈMES COURANTS

### "Erreur : fichier non trouvé"
```r
# Vérifier où vous êtes
getwd()

# Si ce n'est pas le bon dossier :
setwd("/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION")
```

### "Erreur : package non trouvé"
```r
# Installer le package manuellement
install.packages("nom_du_package")
```

### "Erreur : dataset_complet non trouvé"
```r
# Refaire l'étape 5 (combiner les données)
source("01_Donnees/combinaison_donnees.R")
dataset_complet <- combiner_toutes_donnees()
```

---

## ✅ CHECKLIST - CE QUI DOIT FONCTIONNER

- [ ] R s'ouvre correctement
- [ ] Vous êtes dans le bon dossier (`getwd()`)
- [ ] Les packages sont installés
- [ ] `dataset_complet.csv` existe (225,687 lignes)
- [ ] Les graphiques sont dans `figures/`
- [ ] Les prévisions sont dans `data/previsions_24h.csv`

---

## 🎉 C'EST TOUT !

**Si vous suivez ces étapes dans l'ordre, tout devrait fonctionner !**

**Besoin d'aide ?** Relisez cette page étape par étape.

**Vous êtes bloqué ?** Vérifiez la section "Problèmes courants" ci-dessus.

---

## 📞 COMMANDES RAPIDES À RETENIR

```r
# Voir où je suis
getwd()

# Aller dans le dossier du projet
setwd("/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION")

# Voir les fichiers dans le dossier actuel
list.files()

# Charger un script
source("chemin/vers/script.R")

# Voir les premières lignes d'un fichier
head(read.csv("fichier.csv"))
```

---

**Bon courage ! 💪**

