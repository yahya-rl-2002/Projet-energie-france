# =============================================================================
# COLLECTE DE DONNÉES PUBLIQUES FRANÇAISES
# =============================================================================
# Ce script collecte des données depuis plusieurs sources publiques françaises

# Charger les packages nécessaires
library(tidyverse)
library(lubridate)
library(httr)
library(jsonlite)
library(data.table)

# =============================================================================
# 1. INSEE (Institut National de la Statistique)
# =============================================================================

collecte_INSEE <- function() {
  cat("📊 Collecte des données INSEE...\n")
  
  # Installer si nécessaire: install.packages("insee")
  if (!require("insee", quietly = TRUE)) {
    cat("⚠️ Package 'insee' non installé. Installation...\n")
    install.packages("insee")
    library(insee)
  }
  
  # Configuration (clé API gratuite sur https://api.insee.fr)
  # insee::set_insee_key("VOTRE_CLE_API")
  
  # PIB trimestriel (ID: 010569847)
  cat("  → PIB trimestriel...\n")
  tryCatch({
    pib <- insee::get_insee_idbank("010569847")
    write.csv(pib, "data/INSEE_pib.csv", row.names = FALSE)
    cat("  ✅ PIB collecté\n")
  }, error = function(e) {
    cat("  ⚠️ Erreur collecte PIB:", e$message, "\n")
  })
  
  # Inflation - IPC (ID: 001759950)
  cat("  → Inflation (IPC)...\n")
  tryCatch({
    inflation <- insee::get_insee_idbank("001759950")
    write.csv(inflation, "data/INSEE_inflation.csv", row.names = FALSE)
    cat("  ✅ Inflation collectée\n")
  }, error = function(e) {
    cat("  ⚠️ Erreur collecte inflation:", e$message, "\n")
  })
  
  # Taux de chômage (ID: 001688365)
  cat("  → Taux de chômage...\n")
  tryCatch({
    chomage <- insee::get_insee_idbank("001688365")
    write.csv(chomage, "data/INSEE_chomage.csv", row.names = FALSE)
    cat("  ✅ Chômage collecté\n")
  }, error = function(e) {
    cat("  ⚠️ Erreur collecte chômage:", e$message, "\n")
  })
  
  cat("✅ Collecte INSEE terminée\n\n")
}

# =============================================================================
# 2. RTE (Réseau de Transport d'Électricité)
# =============================================================================

collecte_RTE <- function() {
  cat("⚡ Collecte des données RTE...\n")
  
  # RTE Eco2Mix - Données temps réel et historiques
  # URL: https://www.rte-france.com/eco2mix
  
  # Option 1: Téléchargement manuel depuis le site
  cat("  💡 Pour données RTE complètes:\n")
  cat("     1. Aller sur https://www.rte-france.com/eco2mix\n")
  cat("     2. Télécharger les données historiques\n")
  cat("     3. Placer dans data/RTE/\n\n")
  
  # Option 2: Via API (nécessite authentification)
  # Voir documentation: https://data.rte-france.com
  
  cat("✅ Instructions RTE fournies\n\n")
}

# =============================================================================
# 3. Météo France
# =============================================================================

collecte_meteo <- function() {
  cat("🌡️ Collecte des données Météo France...\n")
  
  # Données publiques Météo France
  base_url <- "https://donneespubliques.meteofrance.fr"
  
  cat("  💡 Pour données météo:\n")
  cat("     1. Aller sur https://donneespubliques.meteofrance.fr\n")
  cat("     2. Télécharger données de température\n")
  cat("     3. Placer dans data/Meteo/\n\n")
  
  # Alternative: API Météo France (nécessite clé)
  # Documentation: https://portail-api.meteofrance.fr
  
  cat("✅ Instructions Météo France fournies\n\n")
}

# =============================================================================
# 4. Eurostat (Données Européennes)
# =============================================================================

collecte_eurostat <- function() {
  cat("🇪🇺 Collecte des données Eurostat...\n")
  
  if (!require("eurostat", quietly = TRUE)) {
    cat("  Installation du package eurostat...\n")
    install.packages("eurostat")
    library(eurostat)
  }
  
  # PIB zone euro
  cat("  → PIB zone euro...\n")
  tryCatch({
    pib_euro <- eurostat::get_eurostat("nama_10_gdp", 
                                       filters = list(geo = "EA19",
                                                      unit = "CP_MEUR",
                                                      na_item = "B1GQ"))
    write.csv(pib_euro, "data/Eurostat_pib_zone_euro.csv", row.names = FALSE)
    cat("  ✅ PIB zone euro collecté\n")
  }, error = function(e) {
    cat("  ⚠️ Erreur:", e$message, "\n")
  })
  
  # Consommation énergétique européenne
  cat("  → Consommation énergétique...\n")
  tryCatch({
    energie_euro <- eurostat::get_eurostat("nrg_bal_c",
                                           filters = list(geo = "FR",
                                                         siec = "TOTAL",
                                                         unit = "GWH"))
    write.csv(energie_euro, "data/Eurostat_energie.csv", row.names = FALSE)
    cat("  ✅ Consommation énergétique collectée\n")
  }, error = function(e) {
    cat("  ⚠️ Erreur:", e$message, "\n")
  })
  
  cat("✅ Collecte Eurostat terminée\n\n")
}

# =============================================================================
# 5. data.gouv.fr (Portail Données Publiques)
# =============================================================================

collecte_datagouv <- function() {
  cat("📊 Collecte depuis data.gouv.fr...\n")
  
  # Utiliser le script dédié pour la collecte complète
  # Chercher le script dans différents emplacements possibles
  script_datagouv <- NULL
  
  # Essayer chemin relatif depuis le dossier actuel
  if (file.exists("01_Donnees/collecte_datagouv.R")) {
    script_datagouv <- "01_Donnees/collecte_datagouv.R"
  } else if (file.exists("collecte_datagouv.R")) {
    script_datagouv <- "collecte_datagouv.R"
  } else {
    # Essayer chemin absolu
    script_absolu <- "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION/01_Donnees/collecte_datagouv.R"
    if (file.exists(script_absolu)) {
      script_datagouv <- script_absolu
    }
  }
  
  if (!is.null(script_datagouv) && file.exists(script_datagouv)) {
    cat("  → Utilisation du script dédié collecte_datagouv.R...\n")
    tryCatch({
      # Source le script (sans exécuter la partie interactive)
      source(script_datagouv)
      
      # Appeler la fonction de collecte
      if (exists("collecte_datagouv_complete")) {
        collecte_datagouv_complete()
      } else {
        cat("  ⚠️ Fonction collecte_datagouv_complete non trouvée\n")
        cat("  💡 Exécutez directement: source('01_Donnees/collecte_datagouv.R')\n")
      }
    }, error = function(e) {
      cat("  ⚠️ Erreur:", e$message, "\n")
      cat("  💡 Exécutez directement: Rscript 01_Donnees/collecte_datagouv.R\n")
    })
  } else {
    cat("  ⚠️ Script collecte_datagouv.R non trouvé\n")
    cat("  💡 Pour collecter les données data.gouv.fr, exécutez:\n")
    cat("     Rscript 01_Donnees/collecte_datagouv.R\n")
    cat("  💡 Ou depuis R:\n")
    cat("     source('01_Donnees/collecte_datagouv.R')\n")
    cat("     collecte_datagouv_complete()\n")
  }
  
  cat("\n✅ Collecte data.gouv.fr terminée\n\n")
}

# =============================================================================
# 6. Yahoo Finance (Actions, Indices)
# =============================================================================

collecte_yahoo_finance <- function() {
  cat("💰 Collecte données Yahoo Finance...\n")
  
  if (!require("quantmod", quietly = TRUE)) {
    install.packages("quantmod")
    library(quantmod)
  }
  
  # CAC 40
  cat("  → CAC 40...\n")
  tryCatch({
    cac40 <- getSymbols("^FCHI", src = "yahoo", auto.assign = FALSE, 
                       from = "2020-01-01")
    write.csv(cac40, "data/Yahoo_CAC40.csv", row.names = TRUE)
    cat("  ✅ CAC 40 collecté\n")
  }, error = function(e) {
    cat("  ⚠️ Erreur:", e$message, "\n")
  })
  
  # Actions françaises (exemples)
  actions_fr <- c("BNP.PA", "SAN.PA", "AIR.PA", "RNO.PA", "OR.PA")
  cat("  → Actions françaises...\n")
  for (symbol in actions_fr) {
    tryCatch({
      data <- getSymbols(symbol, src = "yahoo", auto.assign = FALSE,
                        from = "2020-01-01")
      write.csv(data, paste0("data/Yahoo_", symbol, ".csv"), row.names = TRUE)
      cat("    ✅", symbol, "collecté\n")
    }, error = function(e) {
      cat("    ⚠️", symbol, ":", e$message, "\n")
    })
  }
  
  cat("✅ Collecte Yahoo Finance terminée\n\n")
}

# =============================================================================
# 7. FRED (Federal Reserve - Données US pour comparaison)
# =============================================================================

collecte_FRED <- function() {
  cat("🇺🇸 Collecte données FRED (comparaison US)...\n")
  
  if (!require("fredr", quietly = TRUE)) {
    cat("  Installation du package fredr...\n")
    install.packages("fredr")
    library(fredr)
  }
  
  # Configuration (clé API gratuite sur https://fred.stlouisfed.org)
  # fredr_set_key("VOTRE_CLE_API")
  
  # PIB US (pour comparaison)
  cat("  → PIB US...\n")
  tryCatch({
    pib_us <- fredr(series_id = "GDP",
                   observation_start = as.Date("2020-01-01"))
    write.csv(pib_us, "data/FRED_pib_us.csv", row.names = FALSE)
    cat("  ✅ PIB US collecté\n")
  }, error = function(e) {
    cat("  ⚠️ Erreur:", e$message, "\n")
  })
  
  cat("✅ Collecte FRED terminée\n\n")
}

# =============================================================================
# 8. ADEME (Agence de l'Environnement)
# =============================================================================

collecte_ADEME <- function() {
  cat("🌱 Collecte données ADEME...\n")
  
  cat("  💡 Pour données ADEME:\n")
  cat("     1. Aller sur https://www.ademe.fr\n")
  cat("     2. Section 'Données et statistiques'\n")
  cat("     3. Télécharger données émissions CO2, transition énergétique\n")
  cat("     4. Placer dans data/ADEME/\n\n")
  
  cat("✅ Instructions ADEME fournies\n\n")
}

# =============================================================================
# FONCTION PRINCIPALE
# =============================================================================

collecte_toutes_donnees <- function() {
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  cat("🇫🇷 COLLECTE DE DONNÉES PUBLIQUES FRANÇAISES\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Créer dossier data s'il n'existe pas
  if (!dir.exists("data")) {
    dir.create("data")
    cat("📁 Dossier 'data' créé\n\n")
  }
  
  # Collecter toutes les données
  collecte_INSEE()
  collecte_RTE()
  collecte_meteo()
  collecte_eurostat()
  collecte_datagouv()
  collecte_yahoo_finance()
  collecte_FRED()
  collecte_ADEME()
  
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  cat("✅ COLLECTE TERMINÉE\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  cat("\n💡 Prochaines étapes:\n")
  cat("   1. Vérifier les fichiers dans data/\n")
  cat("   2. Combiner avec vos données (defi1, defi2, defi3)\n")
  cat("   3. Utiliser combinaison_donnees.R\n")
}

# Exécuter si script lancé directement
if (!interactive()) {
  collecte_toutes_donnees()
}

