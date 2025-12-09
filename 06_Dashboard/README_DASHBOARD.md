# 📊 DASHBOARD INTERACTIF

Application Shiny pour visualiser et analyser les données de consommation électrique en France.

## 🚀 Démarrage Rapide

### 1. Installer les dépendances

```r
# Installer les packages nécessaires
install.packages(c("shiny", "shinydashboard", "plotly", "DT", "tidyverse", "forecast", "lubridate"))
```

### 2. Lancer l'application

**Option 1 : Depuis RStudio**
```r
# Ouvrir le fichier app.R dans RStudio
# Cliquer sur "Run App" en haut du fichier
```

**Option 2 : Depuis la console R**
```r
# Depuis le dossier R_VERSION/
setwd("/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION")

# Lancer l'application
shiny::runApp("06_Dashboard")
```

**Option 3 : Depuis le terminal**
```r
# Depuis le dossier 06_Dashboard/
Rscript -e "shiny::runApp()"
```

---

## 📋 Fonctionnalités

### 1. 📈 Vue d'ensemble
- **Statistiques clés** : Consommation moyenne, nombre d'observations, période
- **Graphique temporel** : Visualisation interactive de l'évolution de la consommation
- **Tableau statistique** : Statistiques descriptives (moyenne, médiane, écart-type, etc.)

### 2. 🔮 Prévisions
- **Graphique de prévisions** : Visualisation des prévisions avec intervalles de confiance
- **Sélection d'horizon** : Choisir l'horizon de prévision (1h à 168h)
- **Tableau détaillé** : Détails des prévisions avec intervalles 80% et 95%

### 3. 📊 Scénarios
- **Comparaison visuelle** : Graphique comparant les 3 scénarios (Optimiste, Réaliste, Pessimiste)
- **Statistiques par scénario** : Tableau avec moyenne, min, max, écart-type

### 4. 📉 Analyse
- **Distribution** : Histogramme de la distribution de la consommation
- **Par heure** : Consommation moyenne par heure de la journée
- **Par jour** : Consommation moyenne par jour de la semaine
- **Par mois** : Consommation moyenne par mois

### 5. ℹ️ À propos
- Informations sur le dashboard
- Description des fonctionnalités
- Liste des modèles disponibles

---

## ⚙️ Paramètres

### Période
- Sélectionner la période d'analyse avec le sélecteur de dates
- Par défaut : toute la période disponible

### Horizon de prévision
- Slider pour choisir l'horizon (1h à 168h)
- Par défaut : 24h

### Modèle
- Sélection du modèle (TBATS, ARIMA, ETS)
- Par défaut : TBATS (meilleur modèle identifié)

---

## 📁 Fichiers Requis

L'application nécessite les fichiers suivants dans le dossier `data/` :

### Obligatoires
- `dataset_complet.csv` : Dataset principal avec les données de consommation

### Optionnels (pour les prévisions)
- `previsions_multi_horizons.csv` : Prévisions multi-horizons
- `previsions_scenarios.csv` : Prévisions par scénario
- `statistiques_scenarios.csv` : Statistiques des scénarios

**Note** : Si les fichiers de prévisions ne sont pas disponibles, les onglets correspondants afficheront un message indiquant qu'il faut d'abord exécuter les scripts de prévision.

---

## 🎨 Interface

### Structure
- **Sidebar** : Menu de navigation et paramètres
- **Body** : Contenu principal avec onglets

### Onglets
1. **Vue d'ensemble** : Statistiques et graphique principal
2. **Prévisions** : Visualisation des prévisions
3. **Scénarios** : Comparaison des scénarios
4. **Analyse** : Analyses statistiques détaillées
5. **À propos** : Informations sur l'application

---

## 🔧 Personnalisation

### Modifier les couleurs
Éditer le fichier `app.R` et modifier les couleurs dans :
- `valueBox()` : Couleurs des boîtes de statistiques
- `box()` : Couleurs des boîtes de contenu
- `plot_ly()` : Couleurs des graphiques

### Ajouter de nouveaux graphiques
1. Créer une nouvelle fonction `output$nouveau_graphique` dans `server`
2. Ajouter un `plotlyOutput()` dans l'interface `ui`
3. Ajouter un nouvel onglet si nécessaire

### Ajouter de nouveaux modèles
1. Modifier la liste dans `selectInput("modele", ...)`
2. Ajouter la logique d'ajustement dans `server`

---

## 📊 Visualisations Interactives

Tous les graphiques utilisent **Plotly** pour l'interactivité :
- **Zoom** : Cliquer et glisser pour zoomer
- **Pan** : Double-cliquer pour réinitialiser
- **Hover** : Survoler pour voir les valeurs
- **Légende** : Cliquer pour masquer/afficher des séries

---

## ⚠️ Dépannage

### L'application ne se lance pas
1. Vérifier que tous les packages sont installés
2. Vérifier que le fichier `dataset_complet.csv` existe
3. Vérifier les chemins dans la fonction `charger_donnees()`

### Les prévisions ne s'affichent pas
1. Exécuter d'abord les scripts de prévision :
   ```r
   source("05_Prevision/previsions_multi_horizons.R")
   source("05_Prevision/analyse_scenarios.R")
   ```
2. Vérifier que les fichiers CSV sont dans `data/`

### Erreur de mémoire
- Réduire la période sélectionnée
- Filtrer les données avant de les charger

---

## 📚 Ressources

- [Documentation Shiny](https://shiny.rstudio.com/)
- [Documentation Plotly pour R](https://plotly.com/r/)
- [Documentation shinydashboard](https://rstudio.github.io/shinydashboard/)

---

## 🎯 Prochaines Améliorations

- [ ] Export des graphiques en PNG/PDF
- [ ] Export des données en CSV
- [ ] Génération de prévisions en temps réel
- [ ] Comparaison de plusieurs modèles côte à côte
- [ ] Alertes pour valeurs anormales
- [ ] Mode sombre

---

**Développé avec ❤️ en R Shiny**

