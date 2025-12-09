# =============================================================================
# CORRÉLATIONS DÉTAILLÉES
# =============================================================================
# Analyse des corrélations entre toutes les variables

# Configurer miroir CRAN pour éviter les prompts interactifs
options(repos = c(CRAN = "https://cran.rstudio.com/"))

library(tidyverse)

# Charger fonctions utilitaires pour chemins
chemins_utilitaires <- c(
  "../00_Utilitaires/chemins_resultats.R",
  "00_Utilitaires/chemins_resultats.R",
  "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION/00_Utilitaires/chemins_resultats.R"
)
chemin_utilitaires <- NULL
for (chemin in chemins_utilitaires) {
  if (file.exists(chemin)) {
    source(chemin)
    chemin_utilitaires <- chemin
    break
  }
}
if (is.null(chemin_utilitaires)) {
  stop("❌ Fichier chemins_resultats.R non trouvé")
}
library(corrplot)
library(ggplot2)
library(plotly)

# =============================================================================
# CONFIGURATION
# =============================================================================

# Chemins possibles pour le dataset
chemins_dataset <- c(
  "data/dataset_complet.csv",
  "../data/dataset_complet.csv",
  "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION/data/dataset_complet.csv"
)

chemin_dataset <- NULL
for (chemin in chemins_dataset) {
  if (file.exists(chemin)) {
    chemin_dataset <- chemin
    break
  }
}

if (is.null(chemin_dataset)) {
  stop("❌ Dataset complet non trouvé. Exécutez d'abord combinaison_donnees.R")
}

# Créer dossier figures s'il n'existe pas
if (!dir.exists("figures")) {
  dir.create("figures", recursive = TRUE)
}

# =============================================================================
# CHARGER LES DONNÉES
# =============================================================================

charger_dataset <- function() {
  cat("📂 Chargement du dataset complet...\n")
  
  df <- read.csv(chemin_dataset, stringsAsFactors = FALSE)
  df$Date <- as.POSIXct(df$Date)
  
  cat("✅ Dataset chargé:", nrow(df), "observations\n\n")
  
  return(df)
}

# =============================================================================
# MATRICE DE CORRÉLATIONS COMPLÈTE
# =============================================================================

matrice_correlations_complete <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 MATRICE DE CORRÉLATIONS COMPLÈTE\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Sélectionner variables numériques pertinentes
  vars_numeriques <- c(
    "Consommation",
    "Temperature",
    "Heure",
    "Mois",
    "Annee",
    "Conso_totale_communes",
    "Emissions_CO2_EDF",
    "ImpactConsommation",
    "RTE_Consommation",
    "RTE_Nucleaire",
    "RTE_Eolien",
    "RTE_Solaire",
    "RTE_Hydraulique"
  )
  
  vars_presentes <- vars_numeriques[vars_numeriques %in% colnames(df)]
  
  # Ajouter autres variables RTE si disponibles
  vars_rte <- grep("^RTE_", colnames(df), value = TRUE)
  vars_presentes <- c(vars_presentes, vars_rte[!vars_rte %in% vars_presentes])
  
  # Filtrer les colonnes numériques
  df_numerique <- df %>%
    select(all_of(vars_presentes)) %>%
    select_if(is.numeric)
  
  # Supprimer les colonnes avec variance nulle (écart-type = 0)
  # Ces colonnes causent des NaN dans les corrélations
  variances <- sapply(df_numerique, function(x) var(x, na.rm = TRUE))
  colonnes_valides <- names(variances)[!is.na(variances) & variances > 0]
  
  if (length(colonnes_valides) < 2) {
    cat("⚠️ Pas assez de colonnes valides pour calculer les corrélations\n\n")
    return(NULL)
  }
  
  df_numerique <- df_numerique[, colonnes_valides, drop = FALSE]
  
  cat("   Colonnes valides (variance > 0):", length(colonnes_valides), "\n")
  if (length(colonnes_valides) < length(vars_presentes)) {
    colonnes_eliminees <- setdiff(vars_presentes, colonnes_valides)
    cat("   Colonnes éliminées (variance nulle):", paste(colonnes_eliminees, collapse = ", "), "\n")
  }
  cat("\n")
  
  # Calculer corrélations
  cor_matrix <- cor(df_numerique, use = "pairwise.complete.obs")
  
  # Remplacer les NaN/Inf par 0 (colonnes parfaitement corrélées ou avec variance nulle)
  cor_matrix[is.na(cor_matrix)] <- 0
  cor_matrix[is.infinite(cor_matrix)] <- 0
  
  cat("📊 Corrélations calculées pour", ncol(cor_matrix), "variables\n\n")
  
  # Afficher corrélations avec Consommation
  if ("Consommation" %in% rownames(cor_matrix)) {
    cat("🔗 Corrélations avec Consommation:\n\n")
    
    cor_consommation <- cor_matrix["Consommation", ] %>%
      sort(decreasing = TRUE) %>%
      .[. != 1]  # Exclure corrélation avec elle-même
    
    cor_df <- data.frame(
      Variable = names(cor_consommation),
      Correlation = as.numeric(cor_consommation)
    ) %>%
      arrange(desc(abs(Correlation)))
    
    print(cor_df)
    cat("\n")
    
    # Sauvegarder
    write.csv(cor_df, get_path_analyses("correlations_consommation.csv"), row.names = FALSE)
    cat("✅ Corrélations sauvegardées:", get_path_analyses("correlations_consommation.csv"), "\n\n")
  }
  
  # Graphique de corrélations
  cat("📊 Création de la heatmap de corrélations...\n")
  
  # Vérifier qu'il n'y a pas de NaN/Inf dans la matrice
  if (any(is.na(cor_matrix)) || any(is.infinite(cor_matrix))) {
    cat("   ⚠️ NaN/Inf détectés, remplacement par 0...\n")
    cor_matrix[is.na(cor_matrix)] <- 0
    cor_matrix[is.infinite(cor_matrix)] <- 0
  }
  
  # Essayer avec ordre hclust, sinon utiliser ordre alphabétique
  tryCatch({
    png("figures/matrice_correlations.png", width = 1400, height = 1200)
    corrplot(cor_matrix, 
             method = "color",
             type = "upper",
             order = "hclust",
             tl.cex = 0.7,
             tl.col = "black",
             tl.srt = 45,
             addCoef.col = "black",
             number.cex = 0.6,
             col = colorRampPalette(c("blue", "white", "red"))(200))
    dev.off()
    cat("   ✅ Heatmap sauvegardée: figures/matrice_correlations.png\n\n")
  }, error = function(e) {
    cat("   ⚠️ Erreur avec hclust, utilisation de l'ordre alphabétique...\n")
    tryCatch({
      png("figures/matrice_correlations.png", width = 1400, height = 1200)
      corrplot(cor_matrix, 
               method = "color",
               type = "upper",
               order = "original",
               tl.cex = 0.7,
               tl.col = "black",
               tl.srt = 45,
               addCoef.col = "black",
               number.cex = 0.6,
               col = colorRampPalette(c("blue", "white", "red"))(200))
      dev.off()
      cat("   ✅ Heatmap sauvegardée: figures/matrice_correlations.png\n\n")
    }, error = function(e2) {
      cat("   ❌ Erreur lors de la création de la heatmap:", e2$message, "\n\n")
    })
  })
  
  return(cor_matrix)
}

# =============================================================================
# CORRÉLATIONS PAR SAISON
# =============================================================================

correlations_par_saison <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("🌍 CORRÉLATIONS PAR SAISON\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  if (!"Saison" %in% colnames(df)) {
    cat("⚠️ Variable Saison non disponible\n\n")
    return(NULL)
  }
  
  # Variables à analyser
  vars <- c("Consommation", "Temperature", 
            "RTE_Nucleaire", "RTE_Eolien", "RTE_Solaire")
  vars_presentes <- vars[vars %in% colnames(df)]
  
  if (length(vars_presentes) < 2) {
    cat("⚠️ Pas assez de variables pour l'analyse\n\n")
    return(NULL)
  }
  
  resultats <- list()
  
  for (saison in unique(df$Saison[!is.na(df$Saison)])) {
    cat("📊 Saison:", saison, "\n")
    
    df_saison <- df %>%
      filter(Saison == saison) %>%
      select(all_of(vars_presentes)) %>%
      select_if(is.numeric)
    
    if (nrow(df_saison) > 100 && ncol(df_saison) >= 2) {
      cor_saison <- cor(df_saison, use = "pairwise.complete.obs")
      
      if ("Consommation" %in% rownames(cor_saison)) {
        cor_cons <- cor_saison["Consommation", ]
        cat("   Corrélations avec Consommation:\n")
        for (var in names(cor_cons)) {
          if (var != "Consommation") {
            cat("     -", var, ":", round(cor_cons[var], 3), "\n")
          }
        }
        cat("\n")
      }
      
      resultats[[saison]] <- cor_saison
    }
  }
  
  return(resultats)
}

# =============================================================================
# CORRÉLATIONS PAR TYPE DE JOUR
# =============================================================================

correlations_par_type_jour <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📅 CORRÉLATIONS PAR TYPE DE JOUR\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  if (!"TypeJour" %in% colnames(df)) {
    cat("⚠️ Variable TypeJour non disponible\n\n")
    return(NULL)
  }
  
  # Variables à analyser
  vars <- c("Consommation", "Temperature", 
            "RTE_Nucleaire", "RTE_Eolien", "ImpactConsommation")
  vars_presentes <- vars[vars %in% colnames(df)]
  
  if (length(vars_presentes) < 2) {
    cat("⚠️ Pas assez de variables pour l'analyse\n\n")
    return(NULL)
  }
  
  resultats <- list()
  
  for (type in unique(df$TypeJour[!is.na(df$TypeJour)])) {
    cat("📊 Type de jour:", type, "\n")
    
    df_type <- df %>%
      filter(TypeJour == type) %>%
      select(all_of(vars_presentes)) %>%
      select_if(is.numeric)
    
    if (nrow(df_type) > 50 && ncol(df_type) >= 2) {
      cor_type <- cor(df_type, use = "pairwise.complete.obs")
      
      if ("Consommation" %in% rownames(cor_type)) {
        cor_cons <- cor_type["Consommation", ]
        cat("   Corrélations avec Consommation:\n")
        for (var in names(cor_cons)) {
          if (var != "Consommation") {
            cat("     -", var, ":", round(cor_cons[var], 3), "\n")
          }
        }
        cat("\n")
      }
      
      resultats[[type]] <- cor_type
    }
  }
  
  return(resultats)
}

# =============================================================================
# CORRÉLATIONS PAR COULEUR TEMPO
# =============================================================================

correlations_par_tempo <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("🎨 CORRÉLATIONS PAR COULEUR TEMPO\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  if (!"Couleur_TEMPO" %in% colnames(df)) {
    cat("⚠️ Variable Couleur_TEMPO non disponible\n\n")
    return(NULL)
  }
  
  # Variables à analyser
  vars <- c("Consommation", "Temperature", 
            "RTE_Nucleaire", "RTE_Eolien", "RTE_Solaire")
  vars_presentes <- vars[vars %in% colnames(df)]
  
  if (length(vars_presentes) < 2) {
    cat("⚠️ Pas assez de variables pour l'analyse\n\n")
    return(NULL)
  }
  
  resultats <- list()
  
  for (couleur in c("Rouge", "Blanc", "Bleu")) {
    cat("📊 TEMPO", couleur, ":\n")
    
    df_tempo <- df %>%
      filter(Couleur_TEMPO == couleur) %>%
      select(all_of(vars_presentes)) %>%
      select_if(is.numeric)
    
    if (nrow(df_tempo) > 50 && ncol(df_tempo) >= 2) {
      cor_tempo <- cor(df_tempo, use = "pairwise.complete.obs")
      
      if ("Consommation" %in% rownames(cor_tempo)) {
        cor_cons <- cor_tempo["Consommation", ]
        cat("   Corrélations avec Consommation:\n")
        for (var in names(cor_cons)) {
          if (var != "Consommation") {
            cat("     -", var, ":", round(cor_cons[var], 3), "\n")
          }
        }
        cat("\n")
      }
      
      resultats[[couleur]] <- cor_tempo
    }
  }
  
  return(resultats)
}

# =============================================================================
# GRAPHIQUES DE CORRÉLATIONS
# =============================================================================

creer_graphiques_correlations <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 CRÉATION DES GRAPHIQUES DE CORRÉLATIONS\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Scatter plots Consommation vs Variables importantes
  vars_importantes <- c("Temperature", "RTE_Nucleaire", "RTE_Eolien", 
                        "ImpactConsommation", "Heure")
  vars_presentes <- vars_importantes[vars_importantes %in% colnames(df)]
  
  if (length(vars_presentes) > 0) {
    cat("📊 Création des scatter plots...\n")
    
    plots <- list()
    
    for (var in vars_presentes) {
      if (sum(!is.na(df[[var]])) > 100) {
        p <- ggplot(df, aes_string(x = var, y = "Consommation")) +
          geom_point(alpha = 0.1, color = "steelblue") +
          geom_smooth(method = "lm", color = "red", se = TRUE) +
          labs(title = paste("Consommation vs", var),
               x = var, y = "Consommation (MW)") +
          theme_minimal()
        
        plots[[var]] <- p
      }
    }
    
    # Sauvegarder
    if (length(plots) > 0) {
      png("figures/scatter_correlations.png", 
          width = 1400, height = 800)
      do.call(grid.arrange, c(plots, ncol = min(3, length(plots))))
      dev.off()
      
      cat("   ✅ Graphiques sauvegardés: figures/scatter_correlations.png\n\n")
    }
  }
}

# =============================================================================
# FONCTION PRINCIPALE
# =============================================================================

analyser_correlations_completes <- function() {
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  cat("🔗 ANALYSE DES CORRÉLATIONS DÉTAILLÉES\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Charger les données
  df <- charger_dataset()
  
  # Installer packages si nécessaire
  if (!require("corrplot", quietly = TRUE)) {
    install.packages("corrplot", repos = "https://cran.rstudio.com/", quiet = TRUE)
    library(corrplot)
  }
  
  if (!require("gridExtra", quietly = TRUE)) {
    install.packages("gridExtra", repos = "https://cran.rstudio.com/", quiet = TRUE)
    library(gridExtra)
  }
  
  # 1. Matrice de corrélations complète
  cor_matrix <- matrice_correlations_complete(df)
  
  # 2. Corrélations par saison
  cor_saisons <- correlations_par_saison(df)
  
  # 3. Corrélations par type de jour
  cor_types <- correlations_par_type_jour(df)
  
  # 4. Corrélations par TEMPO
  cor_tempo <- correlations_par_tempo(df)
  
  # 5. Graphiques
  creer_graphiques_correlations(df)
  
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("✅ ANALYSE DES CORRÉLATIONS TERMINÉE\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  cat("📁 Fichiers créés:\n")
  cat("   - figures/matrice_correlations.png\n")
  cat("   - figures/scatter_correlations.png\n")
  cat("   - data/correlations_consommation.csv\n\n")
  
  return(list(
    cor_matrix = cor_matrix,
    cor_saisons = cor_saisons,
    cor_types = cor_types,
    cor_tempo = cor_tempo
  ))
}

# =============================================================================
# EXÉCUTION
# =============================================================================

if (!interactive()) {
  projet_dir <- "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION"
  if (dir.exists(projet_dir)) {
    setwd(projet_dir)
  }
  
  resultats <- analyser_correlations_completes()
}

