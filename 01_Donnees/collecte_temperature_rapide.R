# =============================================================================
# COLLECTE RAPIDE DE TEMPÉRATURE (PARIS SEULEMENT)
# =============================================================================
# Version optimisée pour collecter rapidement les données de température
# Utilise Paris comme référence (représentatif de la France)

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

# Coordonnées Paris (représentatif de la France)
LAT_PARIS <- 48.8566
LON_PARIS <- 2.3522

# =============================================================================
# FONCTION : COLLECTER UNE ANNÉE
# =============================================================================

collecter_annee <- function(annee) {
  cat("📅", annee, "...")
  
  date_debut <- paste0(annee, "-01-01")
  date_fin <- paste0(annee, "-12-31")
  
  if (annee == year(Sys.Date())) {
    date_fin <- format(Sys.Date(), "%Y-%m-%d")
  }
  
  base_url <- "https://archive-api.open-meteo.com/v1/archive"
  params <- list(
    latitude = LAT_PARIS,
    longitude = LON_PARIS,
    start_date = date_debut,
    end_date = date_fin,
    hourly = "temperature_2m",
    timezone = "Europe/Paris"
  )
  
  tryCatch({
    response <- GET(base_url, query = params, timeout(60))
    
    if (status_code(response) == 200) {
      data <- content(response, "parsed", type = "application/json")
      
      if (!is.null(data$hourly)) {
        dates_str <- unlist(data$hourly$time)
        dates <- as.POSIXct(dates_str, tz = "Europe/Paris")
        temperatures <- unlist(data$hourly$temperature_2m)
        
        df <- data.frame(
          Date = dates,
          Temperature = temperatures
        ) %>%
          filter(!is.na(Temperature), !is.na(Date)) %>%
          arrange(Date) %>%
          distinct(Date, .keep_all = TRUE)  # Éviter doublons
        
        cat(" ✅", nrow(df), "obs horaires\n")
        return(df)
      }
    } else {
      cat(" ❌ Erreur", status_code(response), "\n")
    }
  }, error = function(e) {
    cat(" ❌ Erreur:", e$message, "\n")
  })
  
  return(NULL)
}

# =============================================================================
# COLLECTE COMPLÈTE
# =============================================================================

collecter_temperature_rapide <- function(annee_debut = 2012, annee_fin = 2025) {
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  cat("🌡️ COLLECTE RAPIDE DE TEMPÉRATURE (PARIS)\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  cat("📍 Station: Paris (48.8566°N, 2.3522°E)\n")
  cat("📅 Période:", annee_debut, "-", annee_fin, "\n\n")
  
  annees <- annee_debut:min(annee_fin, year(Sys.Date()))
  liste_temperatures <- list()
  
  for (annee in annees) {
    df_annee <- collecter_annee(annee)
    
    if (!is.null(df_annee)) {
      liste_temperatures[[as.character(annee)]] <- df_annee
      
      # Sauvegarder immédiatement (avec format date complet)
      fichier_annee <- file.path(OUTPUT_DIR, paste0("temperature_", annee, ".csv"))
      df_annee_save <- df_annee
      df_annee_save$Date <- format(df_annee$Date, "%Y-%m-%d %H:%M:%S")
      write.csv(df_annee_save, fichier_annee, row.names = FALSE)
    }
    
    # Pause pour éviter de surcharger l'API
    if (annee < max(annees)) {
      Sys.sleep(2)
    }
  }
  
  # Combiner toutes les années
  if (length(liste_temperatures) > 0) {
    cat("\n🔗 Combinaison des années...\n")
    
    temperature_complete <- bind_rows(liste_temperatures) %>%
      arrange(Date) %>%
      distinct(Date, .keep_all = TRUE)
    
    fichier_final <- file.path(OUTPUT_DIR, "temperature_moyenne_france.csv")
    temperature_complete_save <- temperature_complete
    temperature_complete_save$Date <- format(temperature_complete$Date, "%Y-%m-%d %H:%M:%S")
    write.csv(temperature_complete_save, fichier_final, row.names = FALSE)
    
    cat("\n✅ COLLECTE TERMINÉE!\n")
    cat("   Observations:", nrow(temperature_complete), "\n")
    cat("   Période:", format(min(temperature_complete$Date), "%Y-%m-%d"), 
        "-", format(max(temperature_complete$Date), "%Y-%m-%d"), "\n")
    cat("   Fichier:", fichier_final, "\n\n")
    
    return(temperature_complete)
  } else {
    cat("\n⚠️ Aucune donnée collectée\n")
    return(NULL)
  }
}

# =============================================================================
# EXÉCUTION
# =============================================================================

if (!interactive()) {
  temperature_data <- collecter_temperature_rapide(2012, 2025)
}

