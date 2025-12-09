# =============================================================================
# LECTURE DES DONNÉES RTE
# =============================================================================
# Lit tous les fichiers RTE téléchargés depuis le dossier "new data"
# et les combine en un seul dataset

library(tidyverse)
library(lubridate)
library(readxl)
library(data.table)

# =============================================================================
# CONFIGURATION
# =============================================================================

# Chercher les fichiers RTE dans plusieurs emplacements possibles
chemin_new_data <- NULL
chemins_possibles <- c(
  "data/RTE",  # Depuis R_VERSION/
  "../data/RTE",  # Depuis 01_Donnees/
  "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION/data/RTE",
  "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/new data",
  "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION/data/new data"
)

for (chemin in chemins_possibles) {
  if (dir.exists(chemin)) {
    # Vérifier qu'il y a des fichiers RTE
    fichiers_rte <- list.files(chemin, pattern = "RTE.*\\.xls", ignore.case = TRUE)
    if (length(fichiers_rte) > 0) {
      chemin_new_data <- chemin
      break
    }
  }
}

if (is.null(chemin_new_data)) {
  cat("⚠️ Aucun dossier RTE trouvé avec des fichiers .xls\n")
  chemin_new_data <- "data/RTE"  # Par défaut
}

# =============================================================================
# FONCTION : LIRE UN FICHIER RTE ANNUEL
# =============================================================================

lire_fichier_RTE_annuel <- function(fichier) {
  cat("📂 Lecture", basename(fichier), "...\n")
  
  tryCatch({
    # Essayer de lire comme Excel
    df <- read_excel(fichier, sheet = 1)
    
    # Si ça ne marche pas, essayer comme CSV (certains fichiers .xls sont en fait des CSV)
    if (nrow(df) == 0 || ncol(df) == 0) {
      cat("   ⚠️ Tentative lecture comme CSV...\n")
      df <- read_delim(fichier, delim = "\t", locale = locale(encoding = "ISO-8859-1"))
    }
    
    cat("   ✅", nrow(df), "lignes,", ncol(df), "colonnes\n")
    return(df)
    
  }, error = function(e) {
    cat("   ❌ Erreur:", e$message, "\n")
    # Essayer comme CSV avec différents séparateurs
    tryCatch({
      df <- read_delim(fichier, delim = "\t", locale = locale(encoding = "ISO-8859-1"))
      cat("   ✅ Lecture CSV réussie:", nrow(df), "lignes\n")
      return(df)
    }, error = function(e2) {
      tryCatch({
        df <- read_delim(fichier, delim = ";", locale = locale(encoding = "ISO-8859-1"))
        cat("   ✅ Lecture CSV réussie:", nrow(df), "lignes\n")
        return(df)
      }, error = function(e3) {
        cat("   ❌ Impossible de lire le fichier\n")
        return(NULL)
      })
    })
  })
}

# =============================================================================
# FONCTION : LIRE TOUS LES FICHIERS ANNUELS
# =============================================================================

lire_tous_fichiers_annuels <- function() {
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 LECTURE DES FICHIERS RTE ANNUELS (2012-2023)\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Liste des fichiers annuels
  fichiers_annuels <- list.files(
    chemin_new_data,
    pattern = "Annuel-Definitif_.*\\.xls",
    full.names = TRUE
  )
  
  cat("📁 Fichiers trouvés:", length(fichiers_annuels), "\n\n")
  
  # Lire chaque fichier
  liste_dfs <- list()
  
  for (fichier in fichiers_annuels) {
    # Extraire l'année du nom de fichier
    annee <- str_extract(basename(fichier), "\\d{4}")
    
    df <- lire_fichier_RTE_annuel(fichier)
    
    if (!is.null(df) && nrow(df) > 0) {
      # Ajouter une colonne année
      df$Annee <- as.numeric(annee)
      liste_dfs[[annee]] <- df
    }
  }
  
  cat("\n✅", length(liste_dfs), "fichiers lus avec succès\n\n")
  
  # Combiner tous les dataframes
  if (length(liste_dfs) > 0) {
    cat("🔗 Combinaison des fichiers...\n")
    
    # Trouver les colonnes communes
    colonnes_communes <- Reduce(intersect, lapply(liste_dfs, colnames))
    cat("   Colonnes communes:", length(colonnes_communes), "\n")
    cat("   Colonnes:", paste(head(colonnes_communes, 10), collapse = ", "), "...\n\n")
    
    # Convertir toutes les colonnes en caractères pour éviter les erreurs de type
    # Puis on reconvertira après la combinaison
    liste_dfs_convertis <- lapply(liste_dfs, function(df) {
      df_subset <- df[, colonnes_communes, drop = FALSE]
      # Convertir toutes les colonnes en caractères
      for (col in colonnes_communes) {
        df_subset[[col]] <- as.character(df_subset[[col]])
      }
      return(df_subset)
    })
    
    # Combiner en gardant seulement les colonnes communes
    df_combine <- bind_rows(liste_dfs_convertis)
    
    # Reconvertir les colonnes numériques
    for (col in colonnes_communes) {
      # Essayer de convertir en numérique
      num_val <- suppressWarnings(as.numeric(df_combine[[col]]))
      if (!all(is.na(num_val)) && sum(!is.na(num_val)) > length(num_val) * 0.1) {
        df_combine[[col]] <- num_val
      }
    }
    
    cat("✅ Dataset combiné:", nrow(df_combine), "observations\n")
    cat("   Période:", min(df_combine$Annee, na.rm = TRUE), "-", 
        max(df_combine$Annee, na.rm = TRUE), "\n\n")
    
    return(df_combine)
  } else {
    cat("❌ Aucun fichier n'a pu être lu\n")
    return(NULL)
  }
}

# =============================================================================
# FONCTION : LIRE FICHIER EN COURS
# =============================================================================

lire_fichier_en_cours <- function() {
  cat("📊 LECTURE DES FICHIERS EN COURS\n")
  cat(paste0(rep("-", 80), collapse = ""), "\n")
  
  fichiers_en_cours <- list.files(
    chemin_new_data,
    pattern = "En-cours.*\\.xls",
    full.names = TRUE
  )
  
  liste_dfs <- list()
  
  for (fichier in fichiers_en_cours) {
    cat("📂 Lecture", basename(fichier), "...\n")
    df <- lire_fichier_RTE_annuel(fichier)
    
    if (!is.null(df) && nrow(df) > 0) {
      type <- ifelse(grepl("Consolide", basename(fichier)), "Consolide", "TR")
      df$Type <- type
      liste_dfs[[basename(fichier)]] <- df
    }
  }
  
  if (length(liste_dfs) > 0) {
    # Combiner
    colonnes_communes <- Reduce(intersect, lapply(liste_dfs, colnames))
    df_combine <- bind_rows(lapply(liste_dfs, function(df) {
      df[, colonnes_communes, drop = FALSE]
    }))
    
    cat("✅ Fichiers en cours combinés:", nrow(df_combine), "observations\n\n")
    return(df_combine)
  }
  
  return(NULL)
}

# =============================================================================
# FONCTION : LIRE FICHIERS TEMPO
# =============================================================================

lire_fichiers_tempo <- function() {
  cat("📊 LECTURE DES CALENDRIERS TEMPO\n")
  cat(paste0(rep("-", 80), collapse = ""), "\n")
  
  fichiers_tempo <- list.files(
    chemin_new_data,
    pattern = "tempo_.*\\.xls",
    full.names = TRUE
  )
  
  cat("📁 Fichiers TEMPO trouvés:", length(fichiers_tempo), "\n\n")
  
  liste_dfs <- list()
  
  for (fichier in fichiers_tempo) {
    cat("📂 Lecture", basename(fichier), "...\n")
    
    tryCatch({
      df <- read_excel(fichier, sheet = 1)
      
      # Extraire la saison du nom de fichier
      saison <- str_extract(basename(fichier), "\\d{4}-\\d{4}")
      df$Saison <- saison
      
      liste_dfs[[basename(fichier)]] <- df
      cat("   ✅", nrow(df), "lignes\n")
      
    }, error = function(e) {
      cat("   ⚠️ Erreur:", e$message, "\n")
    })
  }
  
  if (length(liste_dfs) > 0) {
    # Combiner
    colonnes_communes <- Reduce(intersect, lapply(liste_dfs, colnames))
    df_combine <- bind_rows(lapply(liste_dfs, function(df) {
      df[, colonnes_communes, drop = FALSE]
    }))
    
    cat("\n✅ Calendriers TEMPO combinés:", nrow(df_combine), "observations\n\n")
    return(df_combine)
  }
  
  return(NULL)
}

# =============================================================================
# FONCTION PRINCIPALE : LIRE TOUTES LES DONNÉES RTE
# =============================================================================

lire_toutes_donnees_RTE <- function() {
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  cat("🇫🇷 LECTURE DE TOUTES LES DONNÉES RTE\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  resultats <- list()
  
  # 1. Lire fichiers annuels
  resultats$annuels <- lire_tous_fichiers_annuels()
  
  # 2. Lire fichiers en cours
  resultats$en_cours <- lire_fichier_en_cours()
  
  # 3. Lire fichiers TEMPO
  resultats$tempo <- lire_fichiers_tempo()
  
  # 4. Sauvegarder
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  cat("💾 SAUVEGARDE DES DONNÉES\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Créer dossiers data/RTE dans les deux emplacements possibles
  chemins_sauvegarde <- c(
    "data/RTE",  # Depuis 01_Donnees/
    "../data/RTE"  # Depuis R_VERSION/
  )
  
  for (chemin_save in chemins_sauvegarde) {
    if (!dir.exists(chemin_save)) {
      dir.create(chemin_save, recursive = TRUE)
    }
  }
  
  # Sauvegarder chaque type de données dans les deux emplacements
  if (!is.null(resultats$annuels)) {
    for (chemin_save in chemins_sauvegarde) {
      write.csv(resultats$annuels, 
                file.path(chemin_save, "RTE_annuels_combines.csv"), 
                row.names = FALSE)
    }
    cat("✅ Fichiers annuels sauvegardés: data/RTE/RTE_annuels_combines.csv\n")
  }
  
  if (!is.null(resultats$en_cours)) {
    for (chemin_save in chemins_sauvegarde) {
      write.csv(resultats$en_cours, 
                file.path(chemin_save, "RTE_en_cours_combines.csv"), 
                row.names = FALSE)
    }
    cat("✅ Fichiers en cours sauvegardés: data/RTE/RTE_en_cours_combines.csv\n")
  }
  
  if (!is.null(resultats$tempo)) {
    for (chemin_save in chemins_sauvegarde) {
      write.csv(resultats$tempo, 
                file.path(chemin_save, "RTE_tempo_combines.csv"), 
                row.names = FALSE)
    }
    cat("✅ Calendriers TEMPO sauvegardés: data/RTE/RTE_tempo_combines.csv\n")
  }
  
  cat("\n✅ Toutes les données RTE ont été lues et sauvegardées !\n\n")
  
  # Résumé
  cat("📊 RÉSUMÉ:\n")
  if (!is.null(resultats$annuels)) {
    cat("   - Annuels:", nrow(resultats$annuels), "observations\n")
    cat("     Colonnes:", paste(head(colnames(resultats$annuels), 5), collapse = ", "), "...\n")
  }
  if (!is.null(resultats$en_cours)) {
    cat("   - En cours:", nrow(resultats$en_cours), "observations\n")
  }
  if (!is.null(resultats$tempo)) {
    cat("   - TEMPO:", nrow(resultats$tempo), "observations\n")
  }
  
  return(resultats)
}

# =============================================================================
# EXÉCUTER SI SCRIPT LANCÉ DIRECTEMENT
# =============================================================================

if (!interactive()) {
  # Aller dans le bon dossier
  setwd("/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION/01_Donnees")
  
  # Lire toutes les données
  donnees_RTE <- lire_toutes_donnees_RTE()
}




