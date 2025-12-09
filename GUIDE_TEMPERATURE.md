# 🌡️ GUIDE : AMÉLIORER LES DONNÉES DE TEMPÉRATURE

## 📊 SITUATION ACTUELLE

- **Température** : 57.9% de valeurs manquantes (données simulées)
- **Impact** : Les données simulées limitent la qualité des prévisions

---

## ✅ SOLUTIONS POUR AMÉLIORER

### **Option 1 : API Open-Meteo (Gratuit, Recommandé)** ⭐

L'API Open-Meteo est gratuite et ne nécessite pas de clé API.

#### Avantages
- ✅ Gratuit
- ✅ Pas de clé API nécessaire
- ✅ Données historiques depuis 1940
- ✅ Données horaires disponibles
- ✅ Température moyenne France possible

#### Utilisation

```r
# Depuis R_VERSION/01_Donnees/
source("collecte_temperature.R")

# Collecter pour une période spécifique (recommandé : par années)
# Exemple : 2024 seulement (pour tester)
temperature_2024 <- collecter_openmeteo(
  latitude = 48.8566,  # Paris
  longitude = 2.3522,
  date_debut = "2024-01-01",
  date_fin = "2024-12-31"
)

# Pour toute la période (2012-2025), collecter par années
# pour éviter les timeouts
for (annee in 2012:2025) {
  cat("Collecte", annee, "...\n")
  temp_annee <- collecter_openmeteo(
    48.8566, 2.3522,
    paste0(annee, "-01-01"),
    paste0(annee, "-12-31")
  )
  # Sauvegarder chaque année
  write.csv(temp_annee, 
            paste0("data/Meteo/temperature_", annee, ".csv"),
            row.names = FALSE)
  Sys.sleep(2)  # Pause entre requêtes
}
```

#### Température moyenne France (8 stations)

```r
# Collecter pour plusieurs villes et faire la moyenne
temperature_moyenne <- collecter_temperature_moyenne_france(2012, 2025)
```

**⚠️ Note** : La collecte complète (2012-2025) peut prendre 30-60 minutes car l'API a des limites de débit.

---

### **Option 2 : Données Publiques Météo France** ⭐⭐

#### Avantages
- ✅ Données officielles françaises
- ✅ Très précises
- ✅ Données horaires complètes

#### Comment obtenir

1. **Aller sur** : https://donneespubliques.meteofrance.fr
2. **Chercher** : "Synop" ou "Température"
3. **Télécharger** les données pour les stations principales :
   - **Paris** (code 07015)
   - **Lyon** (code 07480)
   - **Marseille** (code 07650)
   - **Bordeaux** (code 07510)
   - **Lille** (code 07015)
4. **Placer** les fichiers CSV dans `data/Meteo/`
5. **Relancer** `combinaison_donnees.R` - il détectera automatiquement les fichiers

#### Format attendu

Le fichier doit contenir au minimum :
- Une colonne `Date` ou `date` (format : YYYY-MM-DD HH:MM:SS)
- Une colonne `Temperature` ou `temperature` ou `Temp` (en °C)

---

### **Option 3 : API Météo France (Nécessite clé API)**

#### Avantages
- ✅ Données officielles
- ✅ Temps réel + historique
- ✅ Très précises

#### Inscription

1. **Aller sur** : https://portail-api.meteofrance.fr
2. **Créer un compte** (gratuit)
3. **Obtenir une clé API**
4. **Modifier** `collecte_temperature.R` pour utiliser l'API

---

### **Option 4 : Données agrégées (Plus rapide)**

Si vous avez besoin rapidement de données, vous pouvez utiliser des données agrégées quotidiennes et les interpoler à l'heure.

```r
# Exemple : Température moyenne quotidienne
# Puis interpolation horaire
```

---

## 🚀 DÉMARRAGE RAPIDE

### Étape 1 : Collecter les données (Option recommandée)

```r
# Depuis R_VERSION/01_Donnees/
source("collecte_temperature.R")

# Collecter pour 2024 (test rapide)
temperature_2024 <- collecter_openmeteo(48.8566, 2.3522, "2024-01-01", "2024-12-31")
```

### Étape 2 : Vérifier les données

```r
# Vérifier le fichier créé
df_temp <- read.csv("data/Meteo/temperature_moyenne_france.csv")
head(df_temp)
summary(df_temp$Temperature)
```

### Étape 3 : Régénérer le dataset

```r
# Depuis R_VERSION/01_Donnees/
source("combinaison_donnees.R")
combiner_toutes_donnees()
```

Le script détectera automatiquement les nouvelles données de température et les intégrera.

---

## 📊 RÉSULTAT ATTENDU

Après collecte et intégration :
- **Température** : ~0-5% de valeurs manquantes (au lieu de 57.9%)
- **Période** : 2012-2025 (selon les données collectées)
- **Fréquence** : Horaire
- **Qualité** : Données réelles (au lieu de simulées)

---

## ⚡ COLLECTE OPTIMISÉE (Par années)

Pour éviter les timeouts, collecter par années :

```r
# Script optimisé
source("collecte_temperature.R")

annees <- 2012:2025
liste_temperatures <- list()

for (annee in annees) {
  cat("📅 Collecte", annee, "...\n")
  
  date_debut <- paste0(annee, "-01-01")
  date_fin <- paste0(annee, "-12-31")
  
  if (annee == 2025) {
    date_fin <- "2025-11-13"  # Dernière date du dataset
  }
  
  temp_annee <- collecter_openmeteo(48.8566, 2.3522, date_debut, date_fin)
  
  if (!is.null(temp_annee)) {
    liste_temperatures[[as.character(annee)]] <- temp_annee
    # Sauvegarder immédiatement
    write.csv(temp_annee, 
              paste0("data/Meteo/temperature_", annee, ".csv"),
              row.names = FALSE)
    cat("   ✅ Sauvegardé\n")
  }
  
  # Pause pour éviter de surcharger l'API
  Sys.sleep(3)
}

# Combiner toutes les années
if (length(liste_temperatures) > 0) {
  temperature_complete <- bind_rows(liste_temperatures) %>%
    arrange(Date) %>%
    distinct(Date, .keep_all = TRUE)
  
  write.csv(temperature_complete, 
            "data/Meteo/temperature_moyenne_france.csv",
            row.names = FALSE)
  
  cat("\n✅", nrow(temperature_complete), "observations collectées!\n")
}
```

---

## 🔍 VÉRIFICATION

Après collecte, vérifier :

```r
df_temp <- read.csv("data/Meteo/temperature_moyenne_france.csv")
df_temp$Date <- as.POSIXct(df_temp$Date)

cat("Observations:", nrow(df_temp), "\n")
cat("Période:", format(min(df_temp$Date), "%Y-%m-%d"), 
    "-", format(max(df_temp$Date), "%Y-%m-%d"), "\n")
cat("Valeurs manquantes:", sum(is.na(df_temp$Temperature)), 
    "(", round(100*sum(is.na(df_temp$Temperature))/nrow(df_temp), 2), "%)\n")
cat("Température min:", min(df_temp$Temperature, na.rm = TRUE), "°C\n")
cat("Température max:", max(df_temp$Temperature, na.rm = TRUE), "°C\n")
```

---

## 💡 RECOMMANDATION

**Pour une collecte rapide** : Utiliser l'API Open-Meteo avec Paris (48.8566, 2.3522) pour toute la période.

**Pour une meilleure qualité** : Collecter pour plusieurs villes et faire la moyenne (fonction `collecter_temperature_moyenne_france`).

**Pour les données officielles** : Télécharger depuis donneespubliques.meteofrance.fr.

