# 📅 GUIDE : CALENDRIER FRANÇAIS

## ✅ CALENDRIER CRÉÉ AVEC SUCCÈS

Le script `calendrier_francais.R` a créé un calendrier complet avec :
- ✅ **Jours fériés français** (182 jours)
- ✅ **Calendrier TEMPO** (4093 jours : 238 Rouge, 475 Blanc, 3380 Bleu)
- ✅ **Week-ends** (1461 jours)
- ✅ **Variables temporelles** (saison, trimestre, semaine, etc.)

---

## 📁 FICHIER CRÉÉ

### Emplacement
```
PROJET_ENERGIE_FRANCE/R_VERSION/data/Calendrier/calendrier_francais_complet.csv
```

### Contenu
- **Période** : 2012-01-01 à 2025-12-31 (5114 jours)
- **Colonnes** : 23 variables temporelles et événementielles

---

## 📊 VARIABLES DISPONIBLES

### Variables de Base
- `Date` : Date du jour
- `Annee` : Année
- `Mois` : Mois (1-12)
- `Jour` : Jour du mois (1-31)
- `JourSemaine` : Nom du jour (Monday, Tuesday, etc.)
- `NumeroJourSemaine` : Numéro du jour (1=Dimanche, 7=Samedi)

### Variables Événementielles
- `EstWeekend` : TRUE si samedi ou dimanche
- `EstFerie` : TRUE si jour férié
- `Nom_Ferie` : Nom du jour férié (ex: "Jour de l'An", "Noël")
- `Type_Ferie` : Type de férié ("Fixe" ou "Mobile")
- `EstOuvrable` : TRUE si jour ouvrable (lundi-vendredi, non férié)
- `EstPont` : TRUE si jour de pont

### Variables TEMPO
- `Couleur_TEMPO` : Couleur TEMPO ("Rouge", "Blanc", "Bleu" ou NA)
- `Saison_TEMPO` : Saison TEMPO (ex: "2024-2025")
- `EstTEMPO_Rouge` : TRUE si jour TEMPO Rouge
- `EstTEMPO_Blanc` : TRUE si jour TEMPO Blanc
- `EstTEMPO_Bleu` : TRUE si jour TEMPO Bleu

### Variables Temporelles
- `Saison` : Saison météorologique ("Hiver", "Printemps", "Été", "Automne")
- `Trimestre` : Trimestre (1-4)
- `SemaineAnnee` : Semaine de l'année (1-53)
- `JourAnnee` : Jour de l'année (1-366)

### Variables d'Analyse
- `ImpactConsommation` : Score d'impact sur consommation (0-10)
  - 10 : TEMPO Rouge (très haute consommation)
  - 7 : TEMPO Blanc (haute consommation)
  - 6 : Jour ouvrable normal
  - 4 : Week-end
  - 3 : TEMPO Bleu (basse consommation)
  - 2 : Jour férié (faible consommation)
- `TypeJour` : Type de jour ("Férié", "Week-end", "TEMPO Rouge", etc.)

---

## 🚀 UTILISATION

### Option 1 : Charger le calendrier

```r
# Charger le calendrier
calendrier <- read.csv(
  "data/Calendrier/calendrier_francais_complet.csv",
  stringsAsFactors = FALSE
)

# Convertir Date en format date
calendrier$Date <- as.Date(calendrier$Date)

# Explorer
head(calendrier)
summary(calendrier)
```

### Option 2 : Créer/Recréer le calendrier

```r
# Aller dans le dossier du projet
setwd("/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION")

# Charger le script
source("01_Donnees/calendrier_francais.R")

# Créer le calendrier (2012-2025)
calendrier <- creer_calendrier_complet(2012, 2025)
```

### Option 3 : Fusionner avec vos données

```r
# Charger vos données énergétiques
donnees <- read.csv("data/dataset_complet.csv")
donnees$Date <- as.Date(donnees$Date)

# Charger le calendrier
calendrier <- read.csv("data/Calendrier/calendrier_francais_complet.csv")
calendrier$Date <- as.Date(calendrier$Date)

# Fusionner
donnees_avec_calendrier <- merge(
  donnees,
  calendrier,
  by = "Date",
  all.x = TRUE
)

# Ou avec dplyr
library(dplyr)
donnees_avec_calendrier <- donnees %>%
  left_join(calendrier, by = "Date")
```

---

## 📈 EXEMPLES D'ANALYSES

### 1. Analyser l'impact des jours TEMPO

```r
# Consommation moyenne par couleur TEMPO
donnees_avec_calendrier %>%
  group_by(Couleur_TEMPO) %>%
  summarise(
    Consommation_moyenne = mean(Consommation, na.rm = TRUE),
    Consommation_max = max(Consommation, na.rm = TRUE),
    Consommation_min = min(Consommation, na.rm = TRUE)
  )
```

### 2. Comparer jours fériés vs jours normaux

```r
# Consommation par type de jour
donnees_avec_calendrier %>%
  group_by(EstFerie, EstWeekend) %>%
  summarise(
    Consommation_moyenne = mean(Consommation, na.rm = TRUE),
    Nombre_jours = n()
  )
```

### 3. Analyser par saison

```r
# Consommation par saison
donnees_avec_calendrier %>%
  group_by(Saison) %>%
  summarise(
    Consommation_moyenne = mean(Consommation, na.rm = TRUE),
    Temperature_moyenne = mean(Temperature, na.rm = TRUE)
  )
```

### 4. Visualiser les jours TEMPO

```r
library(ggplot2)

# Graphique des jours TEMPO par année
calendrier %>%
  filter(!is.na(Couleur_TEMPO)) %>%
  group_by(Annee, Couleur_TEMPO) %>%
  summarise(Nombre = n()) %>%
  ggplot(aes(x = Annee, y = Nombre, fill = Couleur_TEMPO)) +
  geom_bar(stat = "identity", position = "stack") +
  scale_fill_manual(values = c("Rouge" = "red", "Blanc" = "gray", "Bleu" = "blue")) +
  labs(title = "Répartition des jours TEMPO par année",
       x = "Année", y = "Nombre de jours") +
  theme_minimal()
```

---

## 🎯 UTILISATION DANS LES MODÈLES

### Ajouter comme variables exogènes dans SARIMAX

```r
# Préparer les variables exogènes
variables_exogenes <- calendrier %>%
  select(
    Date,
    EstWeekend,
    EstFerie,
    EstTEMPO_Rouge,
    EstTEMPO_Blanc,
    EstTEMPO_Bleu,
    Saison,
    ImpactConsommation
  ) %>%
  filter(Date >= as.Date("2012-01-01") & Date <= as.Date("2023-12-31"))

# Fusionner avec vos données
donnees_modeles <- merge(donnees, variables_exogenes, by = "Date")

# Utiliser dans SARIMAX
# (voir script modeles_series_temporelles.R)
```

---

## 📊 STATISTIQUES DU CALENDRIER

### Répartition des Jours
- **Total** : 5114 jours (2012-2025)
- **Jours fériés** : 182 (3.6%)
- **Week-ends** : 1461 (28.6%)
- **Jours ouvrables** : 3528 (69.0%)

### Répartition TEMPO
- **Jours TEMPO Rouge** : 238 (4.7%)
- **Jours TEMPO Blanc** : 475 (9.3%)
- **Jours TEMPO Bleu** : 3380 (66.1%)
- **Total jours TEMPO** : 4093 (80.1% des jours)

### Jours Fériés par Type
- **Fixes** : 8 par an (Jour de l'An, Fête du Travail, etc.)
- **Mobiles** : 5 par an (Pâques, Ascension, Pentecôte, etc.)
- **Total** : 13 jours fériés par an

---

## 🔧 PERSONNALISATION

### Modifier la période

```r
# Créer calendrier pour période spécifique
calendrier <- creer_calendrier_complet(2020, 2030)
```

### Ajouter des événements personnalisés

```r
# Ajouter événements (ex: COVID-19, grèves)
calendrier <- calendrier %>%
  mutate(
    EstCOVID = Date >= as.Date("2020-03-17") & Date <= as.Date("2020-05-11"),
    EstGreve = Date %in% as.Date(c("2023-01-19", "2023-03-07", ...))
  )
```

---

## 💡 CONSEILS D'UTILISATION

### Pour la Prévision
1. **Utiliser `ImpactConsommation`** comme variable exogène dans SARIMAX
2. **Créer des variables binaires** pour chaque type de jour
3. **Interagir avec la température** : `ImpactConsommation * Temperature`

### Pour l'Analyse
1. **Grouper par type de jour** pour comparer les patterns
2. **Analyser les jours TEMPO** pour comprendre les pics de consommation
3. **Utiliser les saisons** pour modéliser la saisonnalité

### Pour la Visualisation
1. **Colorier les graphiques** selon la couleur TEMPO
2. **Marquer les jours fériés** sur les séries temporelles
3. **Créer des heatmaps** par jour de semaine et mois

---

## 🆘 PROBLÈMES COURANTS

### Problème : Dates ne correspondent pas

```r
# Vérifier le format des dates
class(donnees$Date)
class(calendrier$Date)

# Convertir si nécessaire
donnees$Date <- as.Date(donnees$Date)
calendrier$Date <- as.Date(calendrier$Date)
```

### Problème : Fusion ne fonctionne pas

```r
# Vérifier les dates communes
intersect(donnees$Date, calendrier$Date)

# Utiliser all.x = TRUE pour garder toutes les dates des données
merge(donnees, calendrier, by = "Date", all.x = TRUE)
```

---

## 📝 NOTES

- Le calendrier TEMPO est disponible de 2014 à 2026
- Les jours fériés sont calculés automatiquement (y compris Pâques mobile)
- Les variables sont optimisées pour l'analyse de consommation énergétique
- Le calendrier peut être étendu facilement pour inclure d'autres événements

---

**✅ Calendrier français prêt à être utilisé dans vos modèles !**

