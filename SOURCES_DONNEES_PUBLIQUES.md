# 📊 SOURCES DE DONNÉES PUBLIQUES FRANÇAISES
## Guide complet pour collecter des données supplémentaires

---

## 🎯 POURQUOI D'AUTRES DONNÉES ?

Vos données (defi1, defi2, defi3) sont excellentes, mais ajouter d'autres données permet de :
- ✅ **Améliorer les prévisions** : Plus de variables = meilleure précision
- ✅ **Comprendre les facteurs** : Qu'est-ce qui influence la consommation ?
- ✅ **Contexte français** : Données officielles françaises
- ✅ **Impressionner** : Montrer votre capacité à collecter et combiner données

---

## 📚 LISTE COMPLÈTE DES SOURCES

### 1. INSEE (Institut National de la Statistique) ⭐ RECOMMANDÉ

#### Données Disponibles
- **PIB trimestriel** : Croissance économique
- **Inflation (IPC)** : Prix à la consommation
- **Taux de chômage** : Activité économique
- **Consommation des ménages** : Dépenses
- **Production industrielle** : Activité industrielle
- **Indicateurs de conjoncture** : Enquêtes

#### Comment Obtenir
1. **API gratuite** : https://api.insee.fr
   - Créer compte gratuit
   - Obtenir clé API
   - Utiliser package R `insee`

2. **Téléchargement manuel** : https://www.insee.fr
   - Section "Statistiques"
   - Télécharger CSV/Excel

#### Code R
```r
library(insee)
insee::set_insee_key("VOTRE_CLE")

# PIB
pib <- get_insee_idbank("010569847")

# Inflation
inflation <- get_insee_idbank("001759950")
```

---

### 2. RTE (Réseau de Transport d'Électricité) ⭐ RECOMMANDÉ

#### Données Disponibles
- **Consommation temps réel** : Données horaires
- **Production par source** : Nucléaire, éolien, solaire, etc.
- **Échanges transfrontaliers** : Avec pays voisins
- **Données historiques** : Depuis 2012

#### Comment Obtenir
1. **Site web** : https://www.rte-france.com/eco2mix
   - Section "Données"
   - Télécharger données historiques
   - Format CSV

2. **API** : https://data.rte-france.com
   - Nécessite authentification
   - Données temps réel

#### Fichiers Disponibles
- Consommation horaire
- Production par filière
- Échanges commerciaux
- Taux de CO2

---

### 3. Météo France ⭐ RECOMMANDÉ

#### Données Disponibles
- **Températures** : Moyenne, min, max
- **Précipitations** : Pluie, neige
- **Ensoleillement** : Heures de soleil
- **Vent** : Vitesse, direction
- **Données historiques** : Depuis 1950

#### Comment Obtenir
1. **Portail données publiques** : https://donneespubliques.meteofrance.fr
   - Téléchargement gratuit
   - Données par station météo
   - Format CSV

2. **API** : https://portail-api.meteofrance.fr
   - Clé API gratuite
   - Données temps réel et prévisions

#### Stations Recommandées
- **Paris** : Impact sur consommation Île-de-France
- **Lyon** : Zone industrielle
- **Marseille** : Zone méditerranéenne
- **Moyenne France** : Température moyenne nationale

---

### 4. Banque de France

#### Données Disponibles
- **Indicateurs de conjoncture** : Enquêtes entreprises/ménages
- **Données monétaires** : Crédit, liquidité
- **Taux d'intérêt** : Taux directeurs
- **Balance commerciale** : Exportations/importations

#### Comment Obtenir
- **Site web** : https://www.banque-france.fr
- **Section "Statistiques"**
- Téléchargement CSV/Excel

---

### 5. Eurostat (Données Européennes)

#### Données Disponibles
- **PIB zone euro** : Comparaison France vs Europe
- **Consommation énergétique** : Comparaisons européennes
- **Indicateurs économiques** : Comparaisons internationales

#### Comment Obtenir
```r
library(eurostat)

# PIB zone euro
pib_euro <- get_eurostat("nama_10_gdp")

# Consommation énergétique
energie <- get_eurostat("nrg_bal_c")
```

**Site** : https://ec.europa.eu/eurostat

---

### 6. data.gouv.fr (Portail Données Publiques)

#### 1000+ Datasets Français Gratuits

#### Catégories Pertinentes
- **Énergie** : Consommation, production, émissions
- **Économie** : Indicateurs économiques
- **Environnement** : Émissions CO2, qualité air
- **Transport** : Mobilité, trafic
- **Bâtiment** : Consommation énergétique bâtiments

#### Comment Obtenir
1. **Site web** : https://www.data.gouv.fr
2. **Rechercher** : "consommation électrique", "énergie", etc.
3. **Télécharger** : CSV, Excel, JSON
4. **API** : https://www.data.gouv.fr/api/1/

#### Exemples de Datasets
- Consommation énergétique par région
- Émissions CO2 par secteur
- Production renouvelable par région
- Efficacité énergétique

---

### 7. ADEME (Agence de l'Environnement)

#### Données Disponibles
- **Émissions CO2** : Par secteur, par région
- **Transition énergétique** : Scénarios
- **Efficacité énergétique** : Indicateurs
- **Énergies renouvelables** : Potentiel, production

#### Comment Obtenir
- **Site web** : https://www.ademe.fr
- **Section "Données et statistiques"**
- Téléchargement gratuit

---

### 8. EDF (Électricité de France)

#### Données Disponibles
- **Production nucléaire** : Par centrale
- **Disponibilité** : Taux de disponibilité
- **Maintenance** : Planning de maintenance
- **Capacité installée** : Par type de centrale

#### Comment Obtenir
- **Rapports annuels** : Disponibles en ligne
- **Données publiques** : Section transparence EDF

---

### 9. Google Trends

#### Données Disponibles
- **Recherches Google** : "consommation électrique", "EDF", etc.
- **Indicateur de sentiment** : Intérêt public
- **Tendances** : Évolution des recherches

#### Comment Obtenir
```r
library(gtrendsR)

# Recherches "consommation électrique" en France
trends <- gtrends("consommation électrique", geo = "FR")
```

---

### 10. Twitter/Social Media (Optionnel)

#### Données Disponibles
- **Sentiment** : Discussions sur énergie
- **Événements** : Détection d'événements
- **Tendances** : Sujets populaires

#### Comment Obtenir
- **Twitter API** : Nécessite compte développeur
- **Packages R** : `rtweet`, `twitteR`

---

## 🔧 GUIDE DE COLLECTE

### Étape 1 : Identifier les Données Nécessaires

Pour améliorer vos prévisions, vous avez besoin de :

1. **Température** 🌡️ (ESSENTIEL)
   - Impact direct sur consommation
   - Source : Météo France

2. **PIB** 📈 (IMPORTANT)
   - Activité économique → Consommation
   - Source : INSEE

3. **Jours fériés** 📅 (IMPORTANT)
   - Réduction consommation
   - Source : Calendrier français

4. **Événements** ⚠️ (UTILE)
   - COVID-19, grèves, etc.
   - Source : Création manuelle

5. **Données sectorielles** 🏭 (BONUS)
   - Production industrielle
   - Source : INSEE

### Étape 2 : Collecter les Données

Utiliser le script `collecte_donnees_publiques.R` :
```r
source("01_Donnees/collecte_donnees_publiques.R")
collecte_toutes_donnees()
```

### Étape 3 : Combiner avec Vos Données

Utiliser le script `combinaison_donnees.R` :
```r
source("01_Donnees/combinaison_donnees.R")
dataset_complet <- combiner_toutes_donnees()
```

---

## 📊 EXEMPLE DE DATASET COMBINÉ

### Structure Finale

```
Date | Consommation | Temperature | PIB | Inflation | Chomage | 
     |             |            |     |           |         |
     | EstWeekend | EstFerie | Heure | Jour | Mois | ...
```

### Variables Créées

- **Temporelles** : Heure, Jour, Mois, Année, JourSemaine
- **Événementielles** : EstWeekend, EstFerie, COVID, Grève
- **Macroéconomiques** : PIB, Inflation, Chômage
- **Météorologiques** : Température, Précipitations
- **Sectorielles** : Production industrielle, etc.

---

## 🎯 RECOMMANDATIONS

### Données Prioritaires (À Collecter en Premier)

1. ⭐⭐⭐ **Température** (Météo France)
   - Impact majeur sur consommation
   - Facile à obtenir

2. ⭐⭐⭐ **PIB** (INSEE)
   - Indicateur économique clé
   - API gratuite disponible

3. ⭐⭐ **Jours fériés** (Calendrier)
   - Impact sur consommation
   - Facile à créer

4. ⭐⭐ **Données RTE officielles** (RTE)
   - Validation de vos données
   - Données complémentaires

### Données Bonus (Pour Impressionner)

5. ⭐ **Eurostat** : Comparaisons européennes
6. ⭐ **ADEME** : Données environnementales
7. ⭐ **Google Trends** : Sentiment public
8. ⭐ **data.gouv.fr** : Datasets supplémentaires

---

## 📝 CHECKLIST DE COLLECTE

- [ ] Température (Météo France)
- [ ] PIB français (INSEE)
- [ ] Inflation (INSEE)
- [ ] Chômage (INSEE)
- [ ] Jours fériés (Calendrier)
- [ ] Données RTE (optionnel)
- [ ] PIB zone euro (Eurostat)
- [ ] Données ADEME (optionnel)
- [ ] Google Trends (optionnel)

---

## 🚀 COMMENCER MAINTENANT

1. **Lire** ce guide
2. **Exécuter** `collecte_donnees_publiques.R`
3. **Vérifier** les fichiers dans `data/`
4. **Combiner** avec `combinaison_donnees.R`
5. **Utiliser** dans vos modèles SARIMAX

---

**📊 Plus de données = Meilleures prévisions !**


