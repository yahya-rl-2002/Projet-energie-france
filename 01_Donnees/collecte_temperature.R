# =============================================================================
# COLLECTE DE DONNÉES DE TEMPÉRATURE
# =============================================================================
# Ce script collecte des données de température réelles depuis plusieurs sources
# pour remplacer les données simulées

library(tidyverse)
library(lubridate)
library(httr)
library(jsonlite)

# Configurer miroir CRAN
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# =============================================================================
# CONFIGURATION
# =============================================================================

OUTPUT_DIR <- "data/Meteo"
if (!dir.exists(OUTPUT_DIR)) {
  dir.create(OUTPUT_DIR, recursive = TRUE)
}

# =============================================================================
# SOURCE 1 : DONNÉES PUBLIQUES MÉTÉO FRANCE (Recommandé)
# =============================================================================

collecter_meteo_france_publique <- function(annee_debut = 2012, annee_fin = 2025) {
  cat("🌡️ Collecte depuis donneespubliques.meteofrance.fr...\n")
  
  # URL des données publiques Météo France
  base_url <- "https://donneespubliques.meteofrance.fr"
  
  cat("   💡 Instructions pour télécharger les données:\n")
  cat("      1. Aller sur: https://donneespubliques.meteofrance.fr\n")
  cat("      2. Chercher 'Température' ou 'Synop'\n")
  cat("      3. Télécharger les données pour les stations principales:\n")
  cat("         - Paris (07015)\n")
  cat("         - Lyon (07480)\n")
  cat("         - Marseille (07650)\n")
  cat("         - Bordeaux (07510)\n")
  cat("         - Lille (07015)\n")
  cat("      4. Placer les fichiers CSV dans:", OUTPUT_DIR, "\n\n")
  
  # Vérifier si des fichiers existent déjà
  fichiers_meteo <- list.files(OUTPUT_DIR, pattern = ".*temperature.*\\.csv|.*meteo.*\\.csv|.*synop.*\\.csv", 
                               ignore.case = TRUE, full.names = TRUE)
  
  if (length(fichiers_meteo) > 0) {
    cat("   ✅ Fichiers météo trouvés:", length(fichiers_meteo), "\n")
    return(fichiers_meteo)
  } else {
    cat("   ⚠️ Aucun fichier météo trouvé dans", OUTPUT_DIR, "\n")
    return(NULL)
  }
}

# =============================================================================
# SOURCE 2 : OPEN-METEO API (Gratuit, sans clé API)
# =============================================================================

collecter_openmeteo <- function(latitude = 46.2276, longitude = 2.2137, 
                                date_debut = "2012-01-01", date_fin = NULL) {
  cat("🌡️ Collecte depuis Open-Meteo API...\n")
  
  if (is.null(date_fin)) {
    date_fin <- format(Sys.Date(), "%Y-%m-%d")
  }
  
  # Open-Meteo API (gratuit, sans clé)
  base_url <- "https://archive-api.open-meteo.com/v1/archive"
  
  # Coordonnées de la France (centre)
  params <- list(
    latitude = latitude,
    longitude = longitude,
    start_date = date_debut,
    end_date = date_fin,
    hourly = "temperature_2m",
    timezone = "Europe/Paris"
  )
  
  tryCatch({
    cat("   📡 Requête API Open-Meteo...\n")
    response <- GET(base_url, query = params, timeout(30))
    
    if (status_code(response) == 200) {
      data <- content(response, "parsed", type = "application/json")
      
      if (!is.null(data$hourly)) {
        # Créer dataframe
        # Les dates sont dans un format ISO 8601 (liste de caractères)
        dates_str <- unlist(data$hourly$time)
        # Essayer différents formats de date
        dates <- tryCatch({
          as.POSIXct(dates_str, format = "%Y-%m-%dT%H:%M", tz = "Europe/Paris")
        }, error = function(e) {
          tryCatch({
            as.POSIXct(dates_str, tz = "Europe/Paris")
          }, error = function(e2) {
            as.POSIXct(dates_str, format = "%Y-%m-%d %H:%M", tz = "Europe/Paris")
          })
        })
        
        temperatures <- unlist(data$hourly$temperature_2m)
        
        df_meteo <- data.frame(
          Date = dates,
          Temperature = temperatures
        )
        
        # Filtrer les valeurs manquantes
        df_meteo <- df_meteo[!is.na(df_meteo$Temperature), ]
        
        cat("   ✅", nrow(df_meteo), "observations collectées\n")
        cat("      Période:", format(min(df_meteo$Date), "%Y-%m-%d"), 
            "-", format(max(df_meteo$Date), "%Y-%m-%d"), "\n")
        
        # Sauvegarder
        fichier_save <- file.path(OUTPUT_DIR, paste0("temperature_openmeteo_", 
                                                     format(Sys.Date(), "%Y%m%d"), ".csv"))
        write.csv(df_meteo, fichier_save, row.names = FALSE)
        cat("   💾 Fichier sauvegardé:", fichier_save, "\n\n")
        
        return(df_meteo)
      } else {
        cat("   ⚠️ Aucune donnée dans la réponse\n")
        return(NULL)
      }
    } else {
      cat("   ⚠️ Erreur API:", status_code(response), "\n")
      return(NULL)
    }
  }, error = function(e) {
    cat("   ⚠️ Erreur lors de la collecte:", e$message, "\n")
    return(NULL)
  })
}

# =============================================================================
# SOURCE 3 : TEMPÉRATURE MOYENNE FRANCE (Agrégation de plusieurs stations)
# =============================================================================

collecter_temperature_moyenne_france <- function(annee_debut = 2012, annee_fin = 2025) {
  cat("🌡️ Calcul température moyenne France (plusieurs stations)...\n")
  cat("   ⚠️ Cette opération peut prendre 30-60 minutes pour toute la période\n")
  cat("   💡 Recommandation : Utiliser une seule station (Paris) pour plus de rapidité\n\n")
  
  # Coordonnées des principales villes françaises
  stations <- data.frame(
    ville = c("Paris", "Lyon", "Marseille", "Bordeaux", "Lille", "Toulouse", "Nantes", "Strasbourg"),
    latitude = c(48.8566, 45.7640, 43.2965, 44.8378, 50.6292, 43.6047, 47.2184, 48.5734),
    longitude = c(2.3522, 4.8357, 5.3698, -0.5792, 3.0573, 1.4442, -1.5536, 7.7521)
  )
  
  cat("   📊 Collecte pour", nrow(stations), "stations...\n")
  
  # Collecter pour chaque station
  liste_temperatures <- list()
  
  for (i in 1:nrow(stations)) {
    ville <- stations$ville[i]
    lat <- stations$latitude[i]
    lon <- stations$longitude[i]
    
    cat("   📍", ville, "...\n")
    
    # Collecter par années pour éviter les limites API
    df_ville <- NULL
    
    for (annee in annee_debut:min(annee_fin, year(Sys.Date()))) {
      date_debut_annee <- paste0(annee, "-01-01")
      date_fin_annee <- paste0(annee, "-12-31")
      
      if (annee == year(Sys.Date())) {
        date_fin_annee <- format(Sys.Date(), "%Y-%m-%d")
      }
      
      df_annee <- collecter_openmeteo(lat, lon, date_debut_annee, date_fin_annee)
      
      if (!is.null(df_annee)) {
        df_annee$Ville <- ville
        if (is.null(df_ville)) {
          df_ville <- df_annee
        } else {
          df_ville <- bind_rows(df_ville, df_annee)
        }
      }
      
      # Pause pour éviter de surcharger l'API
      Sys.sleep(2)
    }
    
    if (!is.null(df_ville)) {
      liste_temperatures[[ville]] <- df_ville
      cat("   ✅", ville, ":", nrow(df_ville), "observations\n")
    }
  }
  
  if (length(liste_temperatures) > 0) {
    # Combiner toutes les stations
    df_toutes_stations <- bind_rows(liste_temperatures)
    
    # Calculer température moyenne par date/heure
    df_moyenne <- df_toutes_stations %>%
      group_by(Date) %>%
      summarise(
        Temperature = mean(Temperature, na.rm = TRUE),
        Temperature_Min = min(Temperature, na.rm = TRUE),
        Temperature_Max = max(Temperature, na.rm = TRUE),
        Nb_Stations = n(),
        .groups = "drop"
      ) %>%
      filter(!is.na(Temperature)) %>%
      arrange(Date)
    
    cat("   ✅ Température moyenne calculée:", nrow(df_moyenne), "observations\n")
    cat("      Période:", format(min(df_moyenne$Date), "%Y-%m-%d"), 
        "-", format(max(df_moyenne$Date), "%Y-%m-%d"), "\n")
    
    # Sauvegarder
    fichier_save <- file.path(OUTPUT_DIR, "temperature_moyenne_france.csv")
    write.csv(df_moyenne, fichier_save, row.names = FALSE)
    cat("   💾 Fichier sauvegardé:", fichier_save, "\n\n")
    
    # Sauvegarder aussi les données par station
    fichier_stations <- file.path(OUTPUT_DIR, "temperature_par_station.csv")
    write.csv(df_toutes_stations, fichier_stations, row.names = FALSE)
    cat("   💾 Données par station sauvegardées:", fichier_stations, "\n\n")
    
    return(df_moyenne)
  } else {
    cat("   ⚠️ Aucune donnée collectée\n")
    return(NULL)
  }
}

# =============================================================================
# SOURCE 4 : LECTURE DE FICHIERS EXISTANTS
# =============================================================================

charger_temperature_existante <- function() {
  cat("📂 Recherche de fichiers température existants...\n")
  
  # Chercher différents formats de fichiers
  patterns <- c("temperature.*\\.csv$", "meteo.*\\.csv$", "temp.*\\.csv$")
  
  fichiers_trouves <- c()
  for (pattern in patterns) {
    fichiers <- list.files(OUTPUT_DIR, pattern = pattern, 
                          ignore.case = TRUE, full.names = TRUE)
    fichiers_trouves <- c(fichiers_trouves, fichiers)
  }
  
  if (length(fichiers_trouves) > 0) {
    cat("   ✅", length(fichiers_trouves), "fichier(s) trouvé(s)\n")
    
    # Essayer de lire le premier fichier
    tryCatch({
      df <- read.csv(fichiers_trouves[1], stringsAsFactors = FALSE)
      
      # Chercher colonnes Date et Temperature
      col_date <- grep("Date|date|Date.*Heure|Heure|heure", colnames(df), 
                      ignore.case = TRUE, value = TRUE)[1]
      col_temp <- grep("Temperature|temperature|Temp|temp", colnames(df), 
                      ignore.case = TRUE, value = TRUE)[1]
      
      if (!is.null(col_date) && !is.null(col_temp)) {
        # Convertir Date
        df$Date <- tryCatch({
          as.POSIXct(df[[col_date]])
        }, error = function(e) {
          as.POSIXct(df[[col_date]], format = "%Y-%m-%d %H:%M:%S")
        })
        
        df_temp <- data.frame(
          Date = df$Date,
          Temperature = as.numeric(df[[col_temp]])
        ) %>%
          filter(!is.na(Temperature), !is.na(Date)) %>%
          arrange(Date)
        
        cat("   ✅", nrow(df_temp), "observations chargées\n")
        cat("      Période:", format(min(df_temp$Date), "%Y-%m-%d"), 
            "-", format(max(df_temp$Date), "%Y-%m-%d"), "\n\n")
        
        return(df_temp)
      }
    }, error = function(e) {
      cat("   ⚠️ Erreur lecture fichier:", e$message, "\n")
    })
  } else {
    cat("   ⚠️ Aucun fichier température trouvé\n")
  }
  
  return(NULL)
}

# =============================================================================
# FONCTION PRINCIPALE
# =============================================================================

collecter_temperature_complete <- function(annee_debut = 2012, annee_fin = 2025, 
                                          utiliser_api = TRUE) {
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  cat("🌡️ COLLECTE DE DONNÉES DE TEMPÉRATURE\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # 1. Vérifier fichiers existants
  df_existant <- charger_temperature_existante()
  
  if (!is.null(df_existant) && nrow(df_existant) > 1000) {
    cat("✅ Utilisation des données existantes\n")
    return(df_existant)
  }
  
  # 2. Collecter depuis API si demandé
  if (utiliser_api) {
    cat("📡 Collecte depuis API Open-Meteo...\n\n")
    
    # Option A : Température moyenne France (recommandé)
    df_meteo <- collecter_temperature_moyenne_france(annee_debut, annee_fin)
    
    if (!is.null(df_meteo)) {
      return(df_meteo)
    }
    
    # Option B : Une seule station (plus rapide)
    cat("📡 Tentative avec une seule station (Paris)...\n")
    df_meteo <- collecter_openmeteo(48.8566, 2.3522, 
                                    paste0(annee_debut, "-01-01"),
                                    paste0(min(annee_fin, year(Sys.Date())), "-12-31"))
    
    if (!is.null(df_meteo)) {
      return(df_meteo)
    }
  }
  
  # 3. Instructions pour téléchargement manuel
  cat("\n💡 ALTERNATIVE : Téléchargement manuel\n")
  collecter_meteo_france_publique(annee_debut, annee_fin)
  
  return(NULL)
}

# =============================================================================
# EXÉCUTION
# =============================================================================

if (!interactive()) {
  # Collecter pour la période du dataset
  temperature_data <- collecter_temperature_complete(2012, 2025, utiliser_api = TRUE)
  
  if (!is.null(temperature_data)) {
    cat("\n✅ Collecte terminée avec succès!\n")
    cat("   Fichier:", file.path(OUTPUT_DIR, "temperature_moyenne_france.csv"), "\n")
  } else {
    cat("\n⚠️ Collecte partielle ou échouée\n")
    cat("   💡 Voir instructions ci-dessus pour téléchargement manuel\n")
  }
}

