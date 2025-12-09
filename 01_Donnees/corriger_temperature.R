# =============================================================================
# CORRIGER FORMAT DES DONNÉES DE TEMPÉRATURE
# =============================================================================
# Corrige les fichiers de température pour avoir le format date/heure complet

library(tidyverse)
library(lubridate)

OUTPUT_DIR <- "data/Meteo"

cat("🔧 Correction du format des données de température...\n\n")

# Lire tous les fichiers par année
annees <- 2012:2025
liste_temps <- list()

for (annee in annees) {
  fichier <- file.path(OUTPUT_DIR, paste0("temperature_", annee, ".csv"))
  
  if (file.exists(fichier)) {
    cat("📅", annee, "...")
    
    df <- read.csv(fichier, stringsAsFactors = FALSE)
    
    # Les données sont horaires mais la date n'affiche que le jour
    # On doit recréer les timestamps horaires
    dates_jour <- unique(substr(df$Date, 1, 10))
    
    # Créer séquence horaire pour l'année
    date_debut <- as.POSIXct(paste0(annee, "-01-01 00:00:00"), tz = "Europe/Paris")
    if (annee == 2025) {
      date_fin <- as.POSIXct("2025-11-13 23:00:00", tz = "Europe/Paris")
    } else {
      date_fin <- as.POSIXct(paste0(annee, "-12-31 23:00:00"), tz = "Europe/Paris")
    }
    
    dates_seq <- seq(date_debut, date_fin, by = "hour")
    
    # Si on a exactement 24 observations par jour, réorganiser
    if (nrow(df) == length(dates_seq)) {
      # Les températures sont dans l'ordre, juste besoin de les associer aux bonnes dates
      df_corrige <- data.frame(
        Date = dates_seq,
        Temperature = df$Temperature[1:length(dates_seq)]
      )
      
      liste_temps[[as.character(annee)]] <- df_corrige
      cat(" ✅", nrow(df_corrige), "obs horaires\n")
    } else {
      # Sinon, essayer de parser directement
      cat(" ⚠️ Format inattendu\n")
    }
  }
}

# Combiner toutes les années
if (length(liste_temps) > 0) {
  cat("\n🔗 Combinaison des années...\n")
  
  temperature_complete <- bind_rows(liste_temps) %>%
    arrange(Date) %>%
    distinct(Date, .keep_all = TRUE) %>%
    filter(!is.na(Temperature), !is.na(Date))
  
  # Sauvegarder avec format date/heure complet
  temperature_complete_save <- temperature_complete
  temperature_complete_save$Date <- format(temperature_complete$Date, "%Y-%m-%d %H:%M:%S")
  
  fichier_final <- file.path(OUTPUT_DIR, "temperature_moyenne_france.csv")
  write.csv(temperature_complete_save, fichier_final, row.names = FALSE)
  
  cat("\n✅ FICHIER CORRIGÉ!\n")
  cat("   Observations:", nrow(temperature_complete), "\n")
  cat("   Période:", format(min(temperature_complete$Date), "%Y-%m-%d %H:%M:%S"), 
      "-", format(max(temperature_complete$Date), "%Y-%m-%d %H:%M:%S"), "\n")
  cat("   Fichier:", fichier_final, "\n")
  cat("   Valeurs manquantes:", sum(is.na(temperature_complete$Temperature)), 
      "(", round(100*sum(is.na(temperature_complete$Temperature))/nrow(temperature_complete), 2), "%)\n\n")
}

