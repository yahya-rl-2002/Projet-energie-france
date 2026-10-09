# =============================================================================
# COMBINAISON DE TOUTES LES DONNÉES
# =============================================================================
# Combine vos données (defi1, defi2, defi3) avec données publiques

library(tidyverse)
library(lubridate)
library(data.table)

# Installer zoo si nécessaire pour interpolation
if (!require("zoo", quietly = TRUE)) {
  install.packages("zoo", repos = "https://cran.rstudio.com/", quiet = TRUE)
}
library(zoo)

# =============================================================================
# CHARGER VOS DONNÉES
# =============================================================================

charger_donnees_consommation <- function(fichier) {
  cat("📂 Chargement", basename(fichier), "...\n")
  
  # Essayer différents séparateurs et encodages
  tryCatch({
    df <- read.csv(fichier, sep = ";", encoding = "latin-1", check.names = FALSE)
  }, error = function(e) {
    tryCatch({
      df <- read.csv(fichier, sep = ",", encoding = "latin-1", check.names = FALSE)
    }, error = function(e2) {
      tryCatch({
        df <- read.csv(fichier, sep = ";", encoding = "UTF-8", check.names = FALSE)
      }, error = function(e3) {
        df <- read.csv(fichier, encoding = "latin-1", check.names = FALSE)
      })
    })
  })
  
  cat("✅", nrow(df), "lignes chargées\n")
  return(df)
}

# =============================================================================
# CHARGER CALENDRIER FRANÇAIS
# =============================================================================

charger_calendrier_francais <- function() {
  cat("📅 Chargement du calendrier français...\n")
  
  # Chercher le calendrier dans différents emplacements possibles
  chemins_possibles <- c(
    "data/Calendrier/calendrier_francais_complet.csv",  # Depuis R_VERSION/
    "../data/Calendrier/calendrier_francais_complet.csv",  # Depuis 01_Donnees/
    "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION/data/Calendrier/calendrier_francais_complet.csv"  # Absolu
  )
  
  chemin_calendrier <- NULL
  for (chemin in chemins_possibles) {
    if (file.exists(chemin)) {
      chemin_calendrier <- chemin
      break
    }
  }
  
  if (is.null(chemin_calendrier)) {
    cat("⚠️ Fichier calendrier non trouvé dans les emplacements suivants:\n")
    for (chemin in chemins_possibles) {
      cat("   -", chemin, "\n")
    }
    cat("   💡 Exécutez d'abord: source('calendrier_francais.R')\n")
    return(NULL)
  }
  
  if (file.exists(chemin_calendrier)) {
    tryCatch({
      calendrier <- read.csv(chemin_calendrier, stringsAsFactors = FALSE)
      
      # Vérifier que le fichier n'est pas vide
      if (nrow(calendrier) > 0 && ncol(calendrier) > 0) {
        # Convertir Date en format Date
        calendrier$Date <- as.Date(calendrier$Date)
        
        # Sélectionner les colonnes importantes
        colonnes_importantes <- c(
          "Date",
          "EstWeekend",
          "EstFerie",
          "Nom_Ferie",
          "Type_Ferie",
          "EstOuvrable",
          "EstPont",
          "Couleur_TEMPO",
          "EstTEMPO_Rouge",
          "EstTEMPO_Blanc",
          "EstTEMPO_Bleu",
          "Saison",
          "ImpactConsommation",
          "TypeJour"
        )
        
        # Garder seulement les colonnes qui existent
        colonnes_existantes <- colonnes_importantes[colonnes_importantes %in% colnames(calendrier)]
        calendrier <- calendrier[, colonnes_existantes, drop = FALSE]
        
        cat("✅ Calendrier français chargé:", nrow(calendrier), "jours\n")
        cat("   Colonnes:", paste(colonnes_existantes, collapse = ", "), "\n")
        
        return(calendrier)
      } else {
        cat("⚠️ Fichier calendrier vide\n")
        return(NULL)
      }
    }, error = function(e) {
      cat("⚠️ Erreur lors du chargement calendrier:", e$message, "\n")
      return(NULL)
    })
  } else {
    cat("⚠️ Fichier calendrier non trouvé:", chemin_calendrier, "\n")
    cat("   💡 Exécutez d'abord: source('calendrier_francais.R')\n")
    return(NULL)
  }
}

# =============================================================================
# CHARGER DONNÉES data.gouv.fr
# =============================================================================

charger_donnees_datagouv <- function() {
  cat("📊 Chargement des données data.gouv.fr...\n")
  
  resultats <- list()
  
  # 1. Consommation énergétique par commune (2011-2023) - TRÈS UTILE
  chemins_possibles <- c(
    "data/data_gouv/Consommation__nerg_tique_2011_2023_par_commune_1.csv",
    "../data/data_gouv/Consommation__nerg_tique_2011_2023_par_commune_1.csv",
    "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION/data/data_gouv/Consommation__nerg_tique_2011_2023_par_commune_1.csv"
  )
  
  chemin_commune <- NULL
  for (chemin in chemins_possibles) {
    if (file.exists(chemin)) {
      chemin_commune <- chemin
      break
    }
  }
  
  if (!is.null(chemin_commune)) {
    tryCatch({
      conso_commune <- read.csv2(chemin_commune, encoding = "UTF-8", check.names = FALSE)
      if (nrow(conso_commune) > 0) {
        # Agréger par année pour avoir des données annuelles
        col_annee <- grep("année|annee|year", colnames(conso_commune), ignore.case = TRUE, value = TRUE)[1]
        col_conso_totale <- grep("conso.*totale|total.*mwh", colnames(conso_commune), ignore.case = TRUE, value = TRUE)[1]
        col_conso_moyenne <- grep("conso.*moyenne|moyenne.*mwh", colnames(conso_commune), ignore.case = TRUE, value = TRUE)[1]
        
        if (!is.na(col_annee) && !is.na(col_conso_totale)) {
          # Utiliser accès direct aux colonnes avec [[
          # Créer un dataframe temporaire avec des noms simples
          conso_temp <- conso_commune
          conso_temp$Annee_temp <- conso_temp[[col_annee]]
          conso_temp$Conso_totale_temp <- as.numeric(conso_temp[[col_conso_totale]])
          
          if (!is.na(col_conso_moyenne)) {
            conso_temp$Conso_moyenne_temp <- as.numeric(conso_temp[[col_conso_moyenne]])
          } else {
            conso_temp$Conso_moyenne_temp <- NA_real_
          }
          
          # Agréger
          conso_commune_agg <- conso_temp %>%
            group_by(Annee_temp) %>%
            summarise(
              Conso_totale_communes = sum(Conso_totale_temp, na.rm = TRUE),
              Conso_moyenne_communes = ifelse(!is.na(col_conso_moyenne),
                                             mean(Conso_moyenne_temp, na.rm = TRUE),
                                             NA_real_),
              .groups = "drop"
            ) %>%
            rename(Annee = Annee_temp)
          
          resultats$conso_commune <- conso_commune_agg
          cat("   ✅ Consommation par commune chargée\n")
        }
      }
    }, error = function(e) {
      cat("   ⚠️ Erreur chargement consommation commune:", e$message, "\n")
    })
  }
  
  # 2. Émissions CO2 EDF
  chemins_co2 <- c(
    "data/data_gouv/_missions_de_CO2_consolid_es_par_pays_du_groupe_ED_1.csv",
    "../data/data_gouv/_missions_de_CO2_consolid_es_par_pays_du_groupe_ED_1.csv",
    "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION/data/data_gouv/_missions_de_CO2_consolid_es_par_pays_du_groupe_ED_1.csv"
  )
  
  chemin_co2 <- NULL
  for (chemin in chemins_co2) {
    if (file.exists(chemin)) {
      chemin_co2 <- chemin
      break
    }
  }
  
  if (!is.null(chemin_co2)) {
    tryCatch({
      # Essayer d'abord avec point-virgule (format français)
      co2_edf <- tryCatch({
        read.csv2(chemin_co2, encoding = "UTF-8", check.names = FALSE)
      }, error = function(e) {
        read.csv(chemin_co2, encoding = "UTF-8", check.names = FALSE)
      })
      if (nrow(co2_edf) > 0) {
        # Chercher colonnes année et émissions
        col_annee <- grep("année|year|annee", colnames(co2_edf), ignore.case = TRUE, value = TRUE)[1]
        col_emissions <- grep("émission|emission|co2", colnames(co2_edf), ignore.case = TRUE, value = TRUE)[1]
        
        if (!is.na(col_annee) && !is.na(col_emissions)) {
          # Utiliser accès direct aux colonnes
          co2_temp <- co2_edf
          co2_temp$Annee_temp <- co2_temp[[col_annee]]
          co2_temp$Emissions_temp <- as.numeric(co2_temp[[col_emissions]])
          
          co2_edf_agg <- co2_temp %>%
            filter(!is.na(Annee_temp), !is.na(Emissions_temp)) %>%
            group_by(Annee_temp) %>%
            summarise(Emissions_CO2_EDF = sum(Emissions_temp, na.rm = TRUE), .groups = "drop") %>%
            rename(Annee = Annee_temp)
          
          resultats$co2_edf <- co2_edf_agg
          cat("   ✅ Émissions CO2 EDF chargées\n")
        }
      }
    }, error = function(e) {
      cat("   ⚠️ Erreur chargement CO2 EDF:", e$message, "\n")
    })
  }
  
  # 3. Consommation et thermosensibilité
  chemins_thermo <- c(
    "data/data_gouv/Consommation_et_thermosensibilit___lectriques_annu_1.csv",
    "../data/data_gouv/Consommation_et_thermosensibilit___lectriques_annu_1.csv",
    "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION/data/data_gouv/Consommation_et_thermosensibilit___lectriques_annu_1.csv"
  )
  
  chemin_thermo <- NULL
  for (chemin in chemins_thermo) {
    if (file.exists(chemin)) {
      chemin_thermo <- chemin
      break
    }
  }
  
  if (!is.null(chemin_thermo)) {
    tryCatch({
      thermo <- read.csv2(chemin_thermo, encoding = "UTF-8", check.names = FALSE)
      if (nrow(thermo) > 0) {
        # Chercher colonne année
        col_annee <- grep("année|year|annee", colnames(thermo), ignore.case = TRUE, value = TRUE)[1]
        if (!is.na(col_annee)) {
          resultats$thermosensibilite <- thermo
          cat("   ✅ Données thermosensibilité chargées\n")
        }
      }
    }, error = function(e) {
      cat("   ⚠️ Erreur chargement thermosensibilité:", e$message, "\n")
    })
  }
  
  if (length(resultats) == 0) {
    cat("   ⚠️ Aucune donnée data.gouv.fr chargée\n")
    return(NULL)
  }
  
  return(resultats)
}

# =============================================================================
# CHARGER DONNÉES RTE
# =============================================================================

charger_donnees_RTE <- function() {
  cat("⚡ Chargement de TOUTES les données RTE (2012-2025)...\n")
  
  # Chemins possibles pour les fichiers RTE
  chemins_annuels <- c(
    "data/RTE/RTE_annuels_combines.csv",
    "../data/RTE/RTE_annuels_combines.csv",
    "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION/data/RTE/RTE_annuels_combines.csv"
  )
  
  chemins_en_cours <- c(
    "data/RTE/RTE_en_cours_combines.csv",
    "../data/RTE/RTE_en_cours_combines.csv",
    "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION/data/RTE/RTE_en_cours_combines.csv"
  )
  
  # 1. Charger données annuelles (2012-2023)
  chemin_annuels <- NULL
  for (chemin in chemins_annuels) {
    if (file.exists(chemin)) {
      chemin_annuels <- chemin
      break
    }
  }
  rte_annuels <- NULL
  
  if (!is.null(chemin_annuels)) {
    tryCatch({
      rte_annuels <- read.csv(chemin_annuels, stringsAsFactors = FALSE, check.names = FALSE)
      if (nrow(rte_annuels) > 0 && ncol(rte_annuels) > 0) {
        cat("   ✅ Données RTE annuelles chargées:", nrow(rte_annuels), "observations\n")
      } else {
        rte_annuels <- NULL
      }
    }, error = function(e) {
      cat("   ⚠️ Erreur chargement RTE annuels:", e$message, "\n")
    })
  }
  
  # 2. Charger données en cours (2024-2025-11-13)
  chemin_en_cours <- NULL
  for (chemin in chemins_en_cours) {
    if (file.exists(chemin)) {
      chemin_en_cours <- chemin
      break
    }
  }
  
  rte_en_cours <- NULL
  
  if (!is.null(chemin_en_cours)) {
    tryCatch({
      rte_en_cours <- read.csv(chemin_en_cours, stringsAsFactors = FALSE, check.names = FALSE)
      if (nrow(rte_en_cours) > 0 && ncol(rte_en_cours) > 0) {
        cat("   ✅ Données RTE en cours chargées:", nrow(rte_en_cours), "observations\n")
      } else {
        rte_en_cours <- NULL
      }
    }, error = function(e) {
      cat("   ⚠️ Erreur chargement RTE en cours:", e$message, "\n")
    })
  }
  
  # 3. Combiner les deux datasets
  if (!is.null(rte_annuels) && !is.null(rte_en_cours)) {
    cat("   🔗 Combinaison des données annuelles + en cours...\n")
    
    # Normaliser les colonnes pour pouvoir combiner
    colonnes_communes <- intersect(colnames(rte_annuels), colnames(rte_en_cours))
    
    if (length(colonnes_communes) > 0) {
      rte_annuels_select <- rte_annuels[, colonnes_communes, drop = FALSE]
      rte_en_cours_select <- rte_en_cours[, colonnes_communes, drop = FALSE]
      
      # Combiner
      rte_complet <- bind_rows(rte_annuels_select, rte_en_cours_select)
      
      cat("   ✅ Données RTE combinées:", nrow(rte_complet), "observations\n")
      cat("   📊 Colonnes:", paste(head(colnames(rte_complet), 5), collapse = ", "), "...\n")
      
      # Afficher la période
      col_date <- grep("Date|date", colnames(rte_complet), ignore.case = TRUE, value = TRUE)[1]
      if (!is.null(col_date) && !is.na(col_date)) {
        tryCatch({
          if ("Date" %in% colnames(rte_complet) && "Heures" %in% colnames(rte_complet)) {
            dates_combinees <- paste(rte_complet$Date, rte_complet$Heures)
            dates_parsed <- as.POSIXct(dates_combinees, format = "%Y-%m-%d %H:%M:%S")
          } else {
            dates_parsed <- tryCatch(
              as.POSIXct(rte_complet[[col_date]]),
              error = function(e) {
                as.POSIXct(rte_complet[[col_date]], format = "%Y-%m-%d %H:%M:%S")
              }
            )
          }
          if (length(dates_parsed) > 0) {
            cat("   📅 Période complète:", format(min(dates_parsed, na.rm = TRUE), "%Y-%m-%d %H:%M:%S"), 
                "-", format(max(dates_parsed, na.rm = TRUE), "%Y-%m-%d %H:%M:%S"), "\n")
          }
        }, error = function(e) {
          # Ignorer les erreurs de parsing
        })
      }
      
      return(rte_complet)
    } else {
      cat("   ⚠️ Aucune colonne commune entre annuels et en cours\n")
      # Retourner celui qui existe
      if (!is.null(rte_annuels)) return(rte_annuels)
      if (!is.null(rte_en_cours)) return(rte_en_cours)
    }
  } else if (!is.null(rte_annuels)) {
    cat("   ℹ️ Utilisation uniquement des données annuelles\n")
    return(rte_annuels)
  } else if (!is.null(rte_en_cours)) {
    cat("   ℹ️ Utilisation uniquement des données en cours\n")
    return(rte_en_cours)
  } else {
    cat("   ⚠️ Aucune donnée RTE disponible\n")
    return(NULL)
  }
}

# =============================================================================
# COMBINER AVEC DONNÉES PUBLIQUES
# =============================================================================

combiner_toutes_donnees <- function() {
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  cat("🔗 COMBINAISON DE TOUTES LES DONNÉES\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # 1. Charger TOUTES les données RTE (2012-2025-11-13)
  cat("1. CHARGEMENT DONNÉES RTE COMPLÈTES (2012-2025-11-13)\n")
  cat(paste0(rep("-", 80), collapse = ""), "\n")
  
  donnees_rte <- charger_donnees_RTE()
  
  # Extraire consommation depuis RTE si disponible
  df_consommation_rte <- NULL
  if (!is.null(donnees_rte)) {
    cat("   📊 Extraction de la consommation depuis RTE...\n")
    
    # Chercher colonne Date dans RTE
    col_date_rte <- grep("Date|date|Date.*Heure|Heure|heure", colnames(donnees_rte), 
                         ignore.case = TRUE, value = TRUE)[1]
    
    # Chercher colonne Consommation dans RTE
    col_conso_rte <- grep("Consommation|consommation|Conso|conso", colnames(donnees_rte), 
                          ignore.case = TRUE, value = TRUE)[1]
    
    if (!is.null(col_date_rte) && !is.null(col_conso_rte)) {
      tryCatch({
        # Gérer le cas où Date et Heures sont séparées (format RTE)
        if ("Date" %in% colnames(donnees_rte) && "Heures" %in% colnames(donnees_rte)) {
          # Combiner Date et Heures
          donnees_rte$Date_RTE <- tryCatch({
            as.POSIXct(paste(donnees_rte$Date, donnees_rte$Heures), format = "%Y-%m-%d %H:%M:%S")
          }, error = function(e) {
            tryCatch({
              as.POSIXct(paste(donnees_rte$Date, donnees_rte$Heures))
            }, error = function(e2) {
              # Essayer format avec date seule
              as.POSIXct(paste(donnees_rte$Date, "12:00:00"))
            })
          })
        } else {
          # Date déjà combinée
          donnees_rte$Date_RTE <- tryCatch({
            as.POSIXct(donnees_rte[[col_date_rte]])
          }, error = function(e) {
            tryCatch({
              as.POSIXct(donnees_rte[[col_date_rte]], format = "%Y-%m-%d %H:%M:%S")
            }, error = function(e2) {
              as.POSIXct(paste(donnees_rte[[col_date_rte]], "12:00:00"))
            })
          })
        }
        
        # Créer dataframe consommation depuis RTE
        df_consommation_rte <- donnees_rte %>%
          select(Date = Date_RTE, Consommation = !!sym(col_conso_rte)) %>%
          filter(!is.na(Consommation), !is.na(Date), Consommation > 0) %>%
          arrange(Date) %>%
          distinct(Date, .keep_all = TRUE)  # Éviter les doublons
        
        cat("   ✅ Consommation RTE extraite:", nrow(df_consommation_rte), "observations\n")
        cat("      Période:", format(min(df_consommation_rte$Date, na.rm = TRUE), "%Y-%m-%d %H:%M:%S"), 
            "-", format(max(df_consommation_rte$Date, na.rm = TRUE), "%Y-%m-%d %H:%M:%S"), "\n")
      }, error = function(e) {
        cat("   ⚠️ Erreur extraction consommation RTE:", e$message, "\n")
        print(traceback())
      })
    } else {
      cat("   ⚠️ Colonnes Date ou Consommation non trouvées dans RTE\n")
      cat("      Colonnes disponibles:", paste(head(colnames(donnees_rte), 10), collapse = ", "), "...\n")
    }
  }
  
  # 2. Utiliser RTE comme source principale (2012-2025-11-13)
  cat("\n2. UTILISATION DES DONNÉES RTE COMPLÈTES\n")
  cat(paste0(rep("-", 80), collapse = ""), "\n")
  
  # Utiliser RTE comme source principale (toutes les données depuis 2012)
  if (!is.null(df_consommation_rte)) {
    df_consommation <- df_consommation_rte
    
    cat("✅ Dataset consommation créé depuis RTE:", nrow(df_consommation), "observations\n")
    cat("   Période:", format(min(df_consommation$Date, na.rm = TRUE), "%Y-%m-%d %H:%M:%S"), 
        "-", format(max(df_consommation$Date, na.rm = TRUE), "%Y-%m-%d %H:%M:%S"), "\n\n")
  } else {
    stop("❌ Aucune donnée RTE disponible. Exécutez d'abord: source('lecture_donnees_RTE.R')")
  }
  
  # 3. Charger données INSEE
  cat("\n3. CHARGEMENT DONNÉES INSEE\n")
  cat(paste0(rep("-", 80), collapse = ""), "\n")
  
  if (file.exists("data/INSEE_pib.csv")) {
    tryCatch({
      pib <- read.csv("data/INSEE_pib.csv")
      # Vérifier que le fichier n'est pas vide
      if (nrow(pib) > 0 && ncol(pib) > 0) {
        cat("✅ PIB chargé\n")
      } else {
        cat("⚠️ Fichier PIB vide\n")
        pib <- NULL
      }
    }, error = function(e) {
      cat("⚠️ Erreur lors du chargement PIB:", e$message, "\n")
      pib <- NULL
    })
  } else {
    cat("⚠️ Fichier PIB non trouvé\n")
    pib <- NULL
  }
  
  if (file.exists("data/INSEE_inflation.csv")) {
    tryCatch({
      # Vérifier d'abord si le fichier est vide
      file_info <- file.info("data/INSEE_inflation.csv")
      if (file_info$size > 0) {
        inflation <- read.csv("data/INSEE_inflation.csv")
        # Vérifier que le fichier contient des données
        if (nrow(inflation) > 0 && ncol(inflation) > 0) {
          cat("✅ Inflation chargée\n")
        } else {
          cat("⚠️ Fichier inflation vide\n")
          inflation <- NULL
        }
      } else {
        cat("⚠️ Fichier inflation vide (0 bytes)\n")
        inflation <- NULL
      }
    }, error = function(e) {
      cat("⚠️ Erreur lors du chargement inflation:", e$message, "\n")
      inflation <- NULL
    })
  } else {
    cat("⚠️ Fichier inflation non trouvé\n")
    inflation <- NULL
  }
  
  # 4. Charger données météo
  cat("\n4. CHARGEMENT DONNÉES MÉTÉO\n")
  cat(paste0(rep("-", 80), collapse = ""), "\n")
  
  # Chercher fichiers température dans plusieurs emplacements et formats
  chemins_meteo <- c(
    "data/Meteo/temperature_moyenne_france.csv",
    "data/Meteo/temperature.csv",
    "../data/Meteo/temperature_moyenne_france.csv",
    "../data/Meteo/temperature.csv",
    "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION/data/Meteo/temperature_moyenne_france.csv"
  )
  
  meteo <- NULL
  chemin_meteo <- NULL
  
  for (chemin in chemins_meteo) {
    if (file.exists(chemin)) {
      chemin_meteo <- chemin
      break
    }
  }
  
  if (!is.null(chemin_meteo)) {
    tryCatch({
      file_info <- file.info(chemin_meteo)
      if (file_info$size > 0) {
        meteo_raw <- read.csv(chemin_meteo, stringsAsFactors = FALSE)
        
        if (nrow(meteo_raw) > 0 && ncol(meteo_raw) > 0) {
          # Chercher colonnes Date et Temperature
          col_date <- grep("Date|date", colnames(meteo_raw), ignore.case = TRUE, value = TRUE)[1]
          col_temp <- grep("Temperature|temperature|Temp|temp", colnames(meteo_raw), 
                          ignore.case = TRUE, value = TRUE)[1]
          
          if (!is.null(col_date) && !is.null(col_temp)) {
            # Convertir Date
            meteo_raw$Date_parsed <- tryCatch({
              as.POSIXct(meteo_raw[[col_date]])
            }, error = function(e) {
              tryCatch({
                as.POSIXct(meteo_raw[[col_date]], format = "%Y-%m-%d %H:%M:%S")
              }, error = function(e2) {
                as.POSIXct(paste(meteo_raw[[col_date]], "12:00:00"))
              })
            })
            
            meteo <- data.frame(
              Date = meteo_raw$Date_parsed,
              Temperature = as.numeric(meteo_raw[[col_temp]])
            ) %>%
              filter(!is.na(Temperature), !is.na(Date)) %>%
              arrange(Date) %>%
              distinct(Date, .keep_all = TRUE)
            
            cat("✅ Température chargée:", nrow(meteo), "observations\n")
            cat("   Période:", format(min(meteo$Date, na.rm = TRUE), "%Y-%m-%d"), 
                "-", format(max(meteo$Date, na.rm = TRUE), "%Y-%m-%d"), "\n")
            cat("   Source:", chemin_meteo, "\n")
          } else {
            cat("⚠️ Colonnes Date ou Temperature non trouvées\n")
            meteo <- NULL
          }
        } else {
          cat("⚠️ Fichier météo vide\n")
          meteo <- NULL
        }
      } else {
        cat("⚠️ Fichier météo vide (0 bytes)\n")
        meteo <- NULL
      }
    }, error = function(e) {
      cat("⚠️ Erreur lors du chargement météo:", e$message, "\n")
      meteo <- NULL
    })
  } else {
    cat("⚠️ Aucun fichier température trouvé\n")
    cat("   💡 Exécutez: source('collecte_temperature.R') pour collecter des données réelles\n")
  }
  
  # NE PLUS CRÉER DE DONNÉES SIMULÉES - Utiliser uniquement les données réelles
  if (is.null(meteo) || nrow(meteo) < 100) {
    cat("⚠️ Données météo insuffisantes\n")
    cat("   💡 Exécutez: source('collecte_temperature_rapide.R') pour collecter des données réelles\n")
    cat("   ⚠️ La colonne Temperature sera laissée avec des valeurs NA\n")
    # Créer un dataframe avec NA pour les dates de consommation
    meteo <- data.frame(
      Date = df_consommation$Date,
      Temperature = NA
    )
  } else {
    # Compléter les dates manquantes avec interpolation
    # Utiliser les dates du dataset consommation comme référence
    dates_completes <- seq(min(df_consommation$Date), 
                          max(df_consommation$Date), 
                          by = "hour")
    
    # Créer dataframe complet avec toutes les dates
    meteo_complete <- data.frame(
      Date = dates_completes
    )
    
    # Joindre avec les données température existantes
    meteo_complete <- meteo_complete %>%
      left_join(meteo %>% select(Date, Temperature), by = "Date")
    
    # Compter les dates manquantes
    dates_manquantes <- sum(is.na(meteo_complete$Temperature))
    
    if (dates_manquantes > 0) {
      cat("   🔧 Interpolation pour", dates_manquantes, "dates manquantes...\n")
      
      # Interpoler les valeurs manquantes
      meteo_ts <- zoo::zoo(meteo_complete$Temperature, meteo_complete$Date)
      meteo_interpole <- zoo::na.approx(meteo_ts, na.rm = FALSE)
      
      # Si encore des NA aux extrémités, utiliser la dernière valeur connue
      meteo_interpole <- zoo::na.locf(meteo_interpole, na.rm = FALSE, fromLast = TRUE)
      meteo_interpole <- zoo::na.locf(meteo_interpole, na.rm = FALSE)
      
      meteo <- data.frame(
        Date = as.POSIXct(index(meteo_interpole)),
        Temperature = as.numeric(coredata(meteo_interpole))
      )
      
      cat("   ✅ Données complétées:", nrow(meteo), "observations\n")
      cat("      Valeurs manquantes après interpolation:", sum(is.na(meteo$Temperature)), "\n")
    } else {
      # Pas besoin d'interpolation, mais s'assurer que toutes les dates sont présentes
      meteo <- meteo_complete
      cat("   ✅ Toutes les dates ont une température\n")
    }
  }
  
  # (Les données Eurostat sont chargées dans collecte_donnees_publiques.R)
  cat(paste0(rep("-", 80), collapse = ""), "\n")
  
  if (file.exists("data/Eurostat_pib_zone_euro.csv")) {
    tryCatch({
      file_info <- file.info("data/Eurostat_pib_zone_euro.csv")
      if (file_info$size > 0) {
        pib_euro <- read.csv("data/Eurostat_pib_zone_euro.csv")
        if (nrow(pib_euro) > 0 && ncol(pib_euro) > 0) {
          cat("✅ PIB zone euro chargé\n")
        } else {
          cat("⚠️ Fichier Eurostat vide\n")
          pib_euro <- NULL
        }
      } else {
        cat("⚠️ Fichier Eurostat vide (0 bytes)\n")
        pib_euro <- NULL
      }
    }, error = function(e) {
      cat("⚠️ Erreur lors du chargement Eurostat:", e$message, "\n")
      pib_euro <- NULL
    })
  } else {
    cat("⚠️ Fichier Eurostat non trouvé\n")
    pib_euro <- NULL
  }
  
  # 5. Charger données data.gouv.fr
  cat("\n5. CHARGEMENT DONNÉES data.gouv.fr\n")
  cat(paste0(rep("-", 80), collapse = ""), "\n")
  
  donnees_datagouv <- charger_donnees_datagouv()
  
  # 6. Intégrer métadonnées RTE (production, échanges, etc.)
  cat("\n6. INTÉGRATION MÉTADONNÉES RTE\n")
  cat(paste0(rep("-", 80), collapse = ""), "\n")
  
  # Les données RTE sont déjà chargées dans donnees_rte (étape 1)
  # On va les utiliser pour ajouter les métadonnées (production, échanges, etc.)
  
  # 7. Charger calendrier français
  cat("\n7. CHARGEMENT CALENDRIER FRANÇAIS\n")
  cat(paste0(rep("-", 80), collapse = ""), "\n")
  
  calendrier <- charger_calendrier_francais()
  
  # 8. Combiner toutes les données
  cat("\n8. COMBINAISON DES DONNÉES\n")
  cat(paste0(rep("-", 80), collapse = ""), "\n")
  
  # Créer dataset combiné avec variables temporelles de base
  df_complet <- df_consommation %>%
    mutate(
      Heure = hour(Date),
      Jour = day(Date),
      Mois = month(Date),
      Annee = year(Date),
      JourSemaine = wday(Date),
      # Extraire la date sans l'heure pour fusionner avec calendrier
      Date_jour = as.Date(Date)
    )
  
  # Fusionner avec le calendrier français
  if (!is.null(calendrier)) {
    cat("   🔗 Fusion avec calendrier français...\n")
    df_complet <- df_complet %>%
      left_join(calendrier, by = c("Date_jour" = "Date"))
    
    # Si EstWeekend du calendrier existe, l'utiliser, sinon créer
    if ("EstWeekend" %in% colnames(df_complet)) {
      # Convertir TRUE/FALSE en 1/0 si nécessaire
      if (is.logical(df_complet$EstWeekend)) {
        df_complet$EstWeekend <- as.numeric(df_complet$EstWeekend)
      }
    } else {
      df_complet$EstWeekend <- ifelse(df_complet$JourSemaine %in% c(1, 7), 1, 0)
    }
    
    # Si EstFerie n'existe pas, créer colonne vide
    if (!"EstFerie" %in% colnames(df_complet)) {
      df_complet$EstFerie <- 0
    } else {
      # Convertir TRUE/FALSE en 1/0 si nécessaire
      if (is.logical(df_complet$EstFerie)) {
        df_complet$EstFerie <- as.numeric(df_complet$EstFerie)
      }
    }
    
    # Convertir autres colonnes logiques en numériques si nécessaire
    colonnes_logiques <- c("EstOuvrable", "EstPont", "EstTEMPO_Rouge", 
                           "EstTEMPO_Blanc", "EstTEMPO_Bleu")
    for (col in colonnes_logiques) {
      if (col %in% colnames(df_complet) && is.logical(df_complet[[col]])) {
        df_complet[[col]] <- as.numeric(df_complet[[col]])
      }
    }
    
    cat("   ✅ Calendrier français intégré\n")
  } else {
    # Si pas de calendrier, créer variables de base
    cat("   ⚠️ Calendrier non disponible, création variables de base\n")
    df_complet <- df_complet %>%
      mutate(
        EstWeekend = ifelse(JourSemaine %in% c(1, 7), 1, 0),
        EstFerie = 0,
        EstOuvrable = ifelse(!EstWeekend & EstFerie == 0, 1, 0)
      )
  }
  
  # Supprimer la colonne Date_jour temporaire
  if ("Date_jour" %in% colnames(df_complet)) {
    df_complet$Date_jour <- NULL
  }
  
  # Joindre avec météo (arrondir les dates à l'heure pour correspondance)
  if (!is.null(meteo)) {
    meteo$Date <- as.POSIXct(meteo$Date)
    # Arrondir les dates à l'heure pour la fusion
    meteo$Date_arrondie <- as.POSIXct(round(as.numeric(meteo$Date) / 3600) * 3600, 
                                      origin = "1970-01-01")
    
    df_complet <- df_complet %>%
      mutate(Date_arrondie = as.POSIXct(round(as.numeric(Date) / 3600) * 3600, 
                                       origin = "1970-01-01")) %>%
      left_join(meteo %>% select(Date_arrondie, Temperature), by = "Date_arrondie") %>%
      select(-Date_arrondie)
    
    cat("   ✅ Température intégrée\n")
    cat("      Observations avec température:", sum(!is.na(df_complet$Temperature)), 
        "sur", nrow(df_complet), "\n")
  }
  
  # Interpoler données INSEE (trimestrielles) sur données horaires
  if (!is.null(pib)) {
    tryCatch({
      # Vérifier que les colonnes nécessaires existent
      if ("Date" %in% colnames(pib) && "PIB" %in% colnames(pib)) {
        # Convertir Date en format approprié si nécessaire
        if (!inherits(pib$Date, "POSIXct") && !inherits(pib$Date, "Date")) {
          pib$Date <- tryCatch(
            as.POSIXct(pib$Date),
            error = function(e) as.Date(pib$Date)
          )
        }
        # Interpolation linéaire
        pib_interp <- approx(as.numeric(pib$Date), pib$PIB, 
                            xout = as.numeric(df_complet$Date), 
                            method = "linear", rule = 2)
        df_complet$PIB <- pib_interp$y
        cat("✅ PIB interpolé\n")
      } else {
        cat("⚠️ Colonnes Date ou PIB manquantes dans fichier PIB\n")
      }
    }, error = function(e) {
      cat("⚠️ Erreur lors de l'interpolation PIB:", e$message, "\n")
    })
  }
  
  # Intégrer données data.gouv.fr (agrégées par année)
  if (!is.null(donnees_datagouv)) {
    cat("\n   🔗 Intégration données data.gouv.fr...\n")
    
    # Consommation par commune (agrégée par année)
    if (!is.null(donnees_datagouv$conso_commune)) {
      df_complet <- df_complet %>%
        left_join(donnees_datagouv$conso_commune, by = "Annee")
      cat("   ✅ Consommation par commune intégrée\n")
    }
    
    # Émissions CO2 EDF (agrégées par année)
    if (!is.null(donnees_datagouv$co2_edf)) {
      df_complet <- df_complet %>%
        left_join(donnees_datagouv$co2_edf, by = "Annee")
      cat("   ✅ Émissions CO2 EDF intégrées\n")
    }
  }
  
  # Intégrer métadonnées RTE (production, échanges, etc.) - on a déjà la consommation
  if (!is.null(donnees_rte)) {
    cat("\n   🔗 Intégration métadonnées RTE (production, échanges, etc.)...\n")
    
    # Préparer Date_RTE si pas déjà fait
    if (!"Date_RTE" %in% colnames(donnees_rte)) {
      if ("Date" %in% colnames(donnees_rte) && "Heures" %in% colnames(donnees_rte)) {
        donnees_rte$Date_RTE <- tryCatch({
          as.POSIXct(paste(donnees_rte$Date, donnees_rte$Heures), format = "%Y-%m-%d %H:%M:%S")
        }, error = function(e) {
          as.POSIXct(paste(donnees_rte$Date, donnees_rte$Heures))
        })
      } else {
        col_date_rte <- grep("Date|date", colnames(donnees_rte), ignore.case = TRUE, value = TRUE)[1]
        if (!is.null(col_date_rte)) {
          donnees_rte$Date_RTE <- tryCatch({
            as.POSIXct(donnees_rte[[col_date_rte]], format = "%Y-%m-%d %H:%M:%S")
          }, error = function(e) {
            as.POSIXct(donnees_rte[[col_date_rte]])
          })
        }
      }
    }
    
    if ("Date_RTE" %in% colnames(donnees_rte)) {
      # Fusionner avec données principales (arrondir les dates à l'heure)
      df_complet <- df_complet %>%
        mutate(Date_arrondie = as.POSIXct(round(as.numeric(Date) / 3600) * 3600, 
                                          origin = "1970-01-01"))
      
      donnees_rte <- donnees_rte %>%
        mutate(Date_arrondie = as.POSIXct(round(as.numeric(Date_RTE) / 3600) * 3600, 
                                         origin = "1970-01-01"))
      
      # Sélectionner colonnes pertinentes de RTE (EXCLURE Consommation car déjà dans df_complet)
      # Inclure explicitement "Nucléaire" avec accent
      cols_rte_pertinentes <- grep("Production|Echange|CO2|Nucleaire|Nucléaire|Eolien|Solaire|Hydraulique|Gaz|Fioul|Charbon|Bioénergies|Pompage|Taux", 
                                   colnames(donnees_rte), 
                                   ignore.case = TRUE, 
                                   value = TRUE)
      
      # Exclure Consommation pour éviter duplication
      cols_rte_pertinentes <- cols_rte_pertinentes[!grepl("Consommation|Conso", cols_rte_pertinentes, ignore.case = TRUE)]
      
      if (length(cols_rte_pertinentes) > 0) {
        # Renommer les colonnes pour éviter les conflits (ajouter préfixe RTE_)
        donnees_rte_select <- donnees_rte %>%
          select(Date_arrondie, all_of(cols_rte_pertinentes)) %>%
          rename_with(~ paste0("RTE_", .x), .cols = -Date_arrondie)
        
        df_complet <- df_complet %>%
          left_join(donnees_rte_select, by = "Date_arrondie") %>%
          select(-Date_arrondie)
        
        cat("   ✅ Métadonnées RTE intégrées (", length(cols_rte_pertinentes), "colonnes)\n")
        cat("      Colonnes:", paste(head(grep("^RTE_", colnames(df_complet), value = TRUE), 5), collapse = ", "), "...\n")
      } else {
        cat("   ⚠️ Aucune colonne pertinente trouvée dans RTE\n")
      }
    } else {
      cat("   ⚠️ Impossible de créer Date_RTE pour intégration métadonnées\n")
    }
  }
  
  # Créer les dossiers data s'ils n'existent pas
  if (!dir.exists("data")) {
    dir.create("data", recursive = TRUE)
  }
  # Créer aussi dans le dossier parent (R_VERSION/data/)
  if (!dir.exists("../data")) {
    dir.create("../data", recursive = TRUE)
  }
  
  # Sauvegarder l'ancien dataset_complet en backup
  if (file.exists("data/dataset_complet.csv")) {
    timestamp_backup <- format(Sys.time(), "%Y%m%d_%H%M%S")
    file.copy("data/dataset_complet.csv", 
              paste0("data/dataset_complet_backup_", timestamp_backup, ".csv"))
    cat("   💾 Ancien dataset sauvegardé en backup\n")
  }
  
  # Sauvegarder nouveau dataset combiné dans les deux emplacements
  write.csv(df_complet, "data/dataset_complet.csv", row.names = FALSE)
  write.csv(df_complet, "../data/dataset_complet.csv", row.names = FALSE)
  
  cat("\n✅ Dataset combiné créé:", nrow(df_complet), "observations\n")
  cat("   Colonnes:", paste(colnames(df_complet), collapse = ", "), "\n")
  cat("   Fichier sauvegardé: data/dataset_complet.csv\n")
  
  return(df_complet)
}

# Exécuter si script lancé directement
if (!interactive()) {
  dataset <- combiner_toutes_donnees()
}

