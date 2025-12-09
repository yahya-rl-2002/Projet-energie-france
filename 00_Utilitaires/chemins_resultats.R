# =============================================================================
# FONCTIONS UTILITAIRES POUR LES CHEMINS DE RÉSULTATS
# =============================================================================
# Ce fichier fournit des fonctions pour déterminer les bons chemins
# pour sauvegarder les résultats dans la nouvelle structure

# =============================================================================
# FONCTION : DÉTERMINER CHEMIN DATA
# =============================================================================

get_data_path <- function() {
  if (file.exists("data")) {
    return("data")
  } else if (file.exists("../data")) {
    return("../data")
  } else {
    return("/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION/data")
  }
}

# =============================================================================
# FONCTION : CHEMIN POUR ANALYSES
# =============================================================================

get_path_analyses <- function(fichier = NULL) {
  base_path <- get_data_path()
  analyses_path <- file.path(base_path, "resultats_nouveaux", "analyses")
  
  # Créer le dossier s'il n'existe pas
  if (!dir.exists(analyses_path)) {
    dir.create(analyses_path, recursive = TRUE)
  }
  
  if (is.null(fichier)) {
    return(analyses_path)
  } else {
    return(file.path(analyses_path, fichier))
  }
}

# =============================================================================
# FONCTION : CHEMIN POUR VALIDATIONS
# =============================================================================

get_path_validations <- function(fichier = NULL) {
  base_path <- get_data_path()
  validations_path <- file.path(base_path, "resultats_nouveaux", "validations")
  
  # Créer le dossier s'il n'existe pas
  if (!dir.exists(validations_path)) {
    dir.create(validations_path, recursive = TRUE)
  }
  
  if (is.null(fichier)) {
    return(validations_path)
  } else {
    return(file.path(validations_path, fichier))
  }
}

# =============================================================================
# FONCTION : CHEMIN POUR PRÉVISIONS
# =============================================================================

get_path_previsions <- function(fichier = NULL) {
  base_path <- get_data_path()
  previsions_path <- file.path(base_path, "resultats_nouveaux", "previsions")
  
  # Créer le dossier s'il n'existe pas
  if (!dir.exists(previsions_path)) {
    dir.create(previsions_path, recursive = TRUE)
  }
  
  if (is.null(fichier)) {
    return(previsions_path)
  } else {
    return(file.path(previsions_path, fichier))
  }
}

# =============================================================================
# FONCTION : CHEMIN POUR MODÈLES
# =============================================================================

get_path_modeles <- function(fichier = NULL) {
  base_path <- get_data_path()
  modeles_path <- file.path(base_path, "resultats_nouveaux", "modeles")
  
  # Créer le dossier s'il n'existe pas
  if (!dir.exists(modeles_path)) {
    dir.create(modeles_path, recursive = TRUE)
  }
  
  if (is.null(fichier)) {
    return(modeles_path)
  } else {
    return(file.path(modeles_path, fichier))
  }
}

# =============================================================================
# FONCTION : CHEMIN POUR FIGURES
# =============================================================================

get_path_figures <- function() {
  if (file.exists("figures")) {
    return("figures")
  } else if (file.exists("../figures")) {
    return("../figures")
  } else {
    return("figures")
  }
}

