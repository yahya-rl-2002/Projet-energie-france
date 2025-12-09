# =============================================================================
# COLLECTE AUTOMATIQUE DES DONNÉES DEPUIS data.gouv.fr
# =============================================================================
# Ce script recherche et télécharge automatiquement des datasets pertinents
# depuis data.gouv.fr via l'API publique

library(tidyverse)
library(httr)
library(jsonlite)
library(readxl)
library(data.table)

# =============================================================================
# CONFIGURATION
# =============================================================================

BASE_URL <- "https://www.data.gouv.fr/api/1"
OUTPUT_DIR <- "data/data_gouv"

# Créer le dossier de sortie
if (!dir.exists(OUTPUT_DIR)) {
  dir.create(OUTPUT_DIR, recursive = TRUE)
  cat("📁 Dossier créé:", OUTPUT_DIR, "\n\n")
}

# =============================================================================
# FONCTION : RECHERCHER DES DATASETS
# =============================================================================

rechercher_datasets <- function(query, page_size = 20, page = 1) {
  cat("🔍 Recherche:", query, "\n")
  
  url <- paste0(BASE_URL, "/datasets/")
  params <- list(
    q = query,
    page_size = page_size,
    page = page,
    format = "csv"  # Préférer CSV
  )
  
  tryCatch({
    response <- GET(url, query = params)
    
    if (status_code(response) != 200) {
      cat("   ⚠️ Erreur HTTP:", status_code(response), "\n")
      return(NULL)
    }
    
    content <- content(response, "parsed", encoding = "UTF-8")
    
    if (is.null(content$data) || length(content$data) == 0) {
      cat("   ℹ️ Aucun résultat trouvé\n")
      return(NULL)
    }
    
    cat("   ✅", length(content$data), "datasets trouvés\n")
    return(content)
    
  }, error = function(e) {
    cat("   ❌ Erreur:", e$message, "\n")
    return(NULL)
  })
}

# =============================================================================
# FONCTION : TÉLÉCHARGER UN FICHIER
# =============================================================================

telecharger_fichier <- function(url, nom_fichier) {
  cat("   📥 Téléchargement:", basename(nom_fichier), "\n")
  
  tryCatch({
    # Télécharger le fichier
    response <- GET(url, timeout(30))
    
    if (status_code(response) != 200) {
      cat("      ⚠️ Erreur HTTP:", status_code(response), "\n")
      return(FALSE)
    }
    
    # Sauvegarder
    writeBin(content(response, "raw"), nom_fichier)
    
    # Vérifier que le fichier existe et n'est pas vide
    if (file.exists(nom_fichier) && file.info(nom_fichier)$size > 0) {
      cat("      ✅ Téléchargé (", 
          round(file.info(nom_fichier)$size / 1024, 2), " KB)\n")
      return(TRUE)
    } else {
      cat("      ⚠️ Fichier vide ou introuvable\n")
      return(FALSE)
    }
    
  }, error = function(e) {
    cat("      ❌ Erreur:", e$message, "\n")
    return(FALSE)
  })
}

# =============================================================================
# FONCTION : TÉLÉCHARGER UN DATASET
# =============================================================================

telecharger_dataset <- function(dataset_id, titre, max_files = 5) {
  cat("\n📦 Dataset:", titre, "\n")
  cat("   ID:", dataset_id, "\n")
  
  # Obtenir les détails du dataset
  url <- paste0(BASE_URL, "/datasets/", dataset_id, "/")
  
  tryCatch({
    response <- GET(url)
    
    if (status_code(response) != 200) {
      cat("   ⚠️ Impossible d'obtenir les détails\n")
      return(FALSE)
    }
    
    dataset <- content(response, "parsed", encoding = "UTF-8")
    
    # Vérifier s'il y a des ressources (fichiers)
    if (is.null(dataset$resources) || length(dataset$resources) == 0) {
      cat("   ℹ️ Aucun fichier disponible\n")
      return(FALSE)
    }
    
    # Filtrer les fichiers CSV, Excel, JSON
    fichiers_pertinents <- dataset$resources %>%
      map_dfr(~ tibble(
        id = .x$id %||% NA,
        url = .x$url %||% NA,
        format = .x$format %||% NA,
        title = .x$title %||% .x$url %||% "sans_titre",
        size = .x$filesize %||% 0
      )) %>%
      filter(
        !is.na(url),
        format %in% c("csv", "xlsx", "xls", "json", "geojson") | 
        str_detect(tolower(url), "\\.(csv|xlsx|xls|json)$")
      ) %>%
      head(max_files)
    
    if (nrow(fichiers_pertinents) == 0) {
      cat("   ℹ️ Aucun fichier CSV/Excel trouvé\n")
      return(FALSE)
    }
    
    cat("   📁", nrow(fichiers_pertinents), "fichier(s) à télécharger\n")
    
    # Télécharger chaque fichier
    fichiers_telecharges <- 0
    
    for (i in 1:nrow(fichiers_pertinents)) {
      fichier <- fichiers_pertinents[i, ]
      
      # Nom de fichier sécurisé
      nom_safe <- str_replace_all(titre, "[^A-Za-z0-9_]", "_") %>%
        str_sub(1, 50)
      
      extension <- ifelse(
        !is.na(fichier$format),
        fichier$format,
        tools::file_ext(fichier$url)
      )
      
      if (extension == "") extension <- "csv"
      
      nom_fichier <- file.path(
        OUTPUT_DIR,
        paste0(nom_safe, "_", i, ".", extension)
      )
      
      # Télécharger
      if (telecharger_fichier(fichier$url, nom_fichier)) {
        fichiers_telecharges <- fichiers_telecharges + 1
      }
      
      # Petite pause pour ne pas surcharger le serveur
      Sys.sleep(0.5)
    }
    
    if (fichiers_telecharges > 0) {
      cat("   ✅", fichiers_telecharges, "fichier(s) téléchargé(s)\n")
      return(TRUE)
    } else {
      return(FALSE)
    }
    
  }, error = function(e) {
    cat("   ❌ Erreur:", e$message, "\n")
    return(FALSE)
  })
}

# =============================================================================
# FONCTION : COLLECTER PAR THÉMATIQUE
# =============================================================================

collecter_par_thematique <- function(queries, max_datasets_per_query = 5) {
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 COLLECTE AUTOMATIQUE DEPUIS data.gouv.fr\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  total_telecharges <- 0
  
  for (query in queries) {
    cat("\n", paste0(rep("-", 80), collapse = ""), "\n")
    cat("🔎 THÉMATIQUE:", toupper(query), "\n")
    cat(paste0(rep("-", 80), collapse = ""), "\n\n")
    
    # Rechercher
    resultats <- rechercher_datasets(query, page_size = max_datasets_per_query)
    
    if (is.null(resultats) || length(resultats$data) == 0) {
      cat("   ⏭️ Passer à la suivante...\n")
      next
    }
    
    # Télécharger les meilleurs résultats
    datasets_a_telecharger <- resultats$data[1:min(max_datasets_per_query, length(resultats$data))]
    
    for (dataset in datasets_a_telecharger) {
      dataset_id <- dataset$id
      titre <- dataset$title %||% dataset$slug %||% "sans_titre"
      
      # Vérifier si déjà téléchargé (éviter doublons)
      nom_safe <- str_replace_all(titre, "[^A-Za-z0-9_]", "_") %>%
        str_sub(1, 50)
      
      fichiers_existants <- list.files(
        OUTPUT_DIR,
        pattern = paste0("^", nom_safe),
        ignore.case = TRUE
      )
      
      if (length(fichiers_existants) > 0) {
        cat("\n⏭️ Dataset déjà téléchargé:", titre, "\n")
        next
      }
      
      # Télécharger
      if (telecharger_dataset(dataset_id, titre)) {
        total_telecharges <- total_telecharges + 1
      }
      
      # Pause entre datasets
      Sys.sleep(1)
    }
  }
  
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("✅ COLLECTE TERMINÉE\n")
  cat("   📁 Fichiers téléchargés:", total_telecharges, "dataset(s)\n")
  cat("   📂 Dossier:", OUTPUT_DIR, "\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  return(total_telecharges)
}

# =============================================================================
# FONCTION PRINCIPALE : COLLECTE COMPLÈTE
# =============================================================================

collecte_datagouv_complete <- function() {
  # Requêtes de recherche pour l'énergie et l'environnement
  queries <- c(
    "consommation électrique",
    "consommation énergétique",
    "émissions CO2",
    "production énergétique",
    "transition énergétique",
    "bilan carbone",
    "énergies renouvelables",
    "efficacité énergétique",
    "sobriété énergétique",
    "mix énergétique"
  )
  
  # Collecter
  total <- collecter_par_thematique(queries, max_datasets_per_query = 3)
  
  # Résumé des fichiers téléchargés
  cat("\n📋 RÉSUMÉ DES FICHIERS TÉLÉCHARGÉS:\n")
  fichiers <- list.files(OUTPUT_DIR, full.names = TRUE)
  
  if (length(fichiers) > 0) {
    for (fichier in fichiers) {
      taille <- file.info(fichier)$size
      cat("   -", basename(fichier), 
          "(", round(taille / 1024, 2), " KB)\n")
    }
  } else {
    cat("   ℹ️ Aucun fichier téléchargé\n")
  }
  
  cat("\n💡 PROCHAINES ÉTAPES:\n")
  cat("   1. Vérifier les fichiers dans", OUTPUT_DIR, "\n")
  cat("   2. Utiliser le script de lecture pour traiter les données\n")
  cat("   3. Combiner avec vos autres données\n\n")
  
  return(total)
}

# =============================================================================
# FONCTION : LIRE ET COMBINER TOUS LES FICHIERS TÉLÉCHARGÉS
# =============================================================================

lire_fichiers_datagouv <- function() {
  cat("📖 Lecture des fichiers téléchargés depuis data.gouv.fr...\n\n")
  
  fichiers <- list.files(OUTPUT_DIR, 
                        pattern = "\\.(csv|xlsx|xls)$",
                        full.names = TRUE,
                        ignore.case = TRUE)
  
  if (length(fichiers) == 0) {
    cat("⚠️ Aucun fichier trouvé dans", OUTPUT_DIR, "\n")
    return(NULL)
  }
  
  cat("📁", length(fichiers), "fichier(s) trouvé(s)\n\n")
  
  liste_dfs <- list()
  
  for (fichier in fichiers) {
    cat("📂", basename(fichier), "\n")
    
    tryCatch({
      # Détecter le type de fichier
      extension <- tolower(tools::file_ext(fichier))
      
      if (extension == "csv") {
        # Essayer différents encodages et séparateurs
        df <- NULL
        
        # Essayer UTF-8 avec point-virgule
        tryCatch({
          df <- read.csv2(fichier, encoding = "UTF-8", check.names = FALSE)
        }, error = function(e) {
          # Essayer UTF-8 avec virgule
          tryCatch({
            df <- read.csv(fichier, encoding = "UTF-8", check.names = FALSE)
          }, error = function(e2) {
            # Essayer latin-1
            tryCatch({
              df <- read.csv2(fichier, encoding = "latin-1", check.names = FALSE)
            }, error = function(e3) {
              # Dernier essai avec data.table
              tryCatch({
                df <- fread(fichier, encoding = "Latin-1")
              }, error = function(e4) {
                cat("      ❌ Impossible de lire le fichier\n")
              })
            })
          })
        })
        
      } else if (extension %in% c("xlsx", "xls")) {
        df <- read_excel(fichier, sheet = 1)
      } else {
        cat("      ⚠️ Format non supporté:", extension, "\n")
        next
      }
      
      if (!is.null(df) && nrow(df) > 0 && ncol(df) > 0) {
        # Ajouter une colonne avec le nom du fichier source
        df$source_fichier <- basename(fichier)
        liste_dfs[[basename(fichier)]] <- df
        
        cat("      ✅", nrow(df), "lignes,", ncol(df), "colonnes\n")
      } else {
        cat("      ⚠️ Fichier vide ou invalide\n")
      }
      
    }, error = function(e) {
      cat("      ❌ Erreur:", e$message, "\n")
    })
  }
  
  if (length(liste_dfs) == 0) {
    cat("\n❌ Aucun fichier n'a pu être lu\n")
    return(NULL)
  }
  
  cat("\n✅", length(liste_dfs), "fichier(s) lu(s) avec succès\n")
  
  # Sauvegarder un résumé
  resume <- tibble(
    fichier = names(liste_dfs),
    lignes = map_int(liste_dfs, nrow),
    colonnes = map_int(liste_dfs, ncol)
  )
  
  write.csv(resume, 
            file.path(OUTPUT_DIR, "resume_fichiers.csv"),
            row.names = FALSE)
  
  cat("📄 Résumé sauvegardé:", file.path(OUTPUT_DIR, "resume_fichiers.csv"), "\n\n")
  
  return(liste_dfs)
}

# =============================================================================
# EXÉCUTION
# =============================================================================

# Exécuter si script lancé directement
if (!interactive()) {
  # Changer vers le bon répertoire
  # Utiliser le chemin absolu du projet
  projet_dir <- "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION"
  if (dir.exists(projet_dir)) {
    setwd(projet_dir)
  }
  
  # Collecter les données
  collecte_datagouv_complete()
  
  # Lire les fichiers téléchargés
  donnees <- lire_fichiers_datagouv()
}

