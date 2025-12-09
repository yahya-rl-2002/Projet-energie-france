# =============================================================================
# VISUALISATIONS CRÉATIVES
# =============================================================================
# Graphiques interactifs et visualisations avancées

# Configurer miroir CRAN pour éviter les prompts interactifs
options(repos = c(CRAN = "https://cran.rstudio.com/"))

library(tidyverse)
library(lubridate)
library(ggplot2)
library(plotly)
library(gridExtra)
library(viridis)

# =============================================================================
# CONFIGURATION
# =============================================================================

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
  stop("❌ Dataset complet non trouvé")
}

if (!dir.exists("figures")) {
  dir.create("figures", recursive = TRUE)
}

# =============================================================================
# CHARGER LES DONNÉES
# =============================================================================

charger_dataset <- function() {
  cat("📂 Chargement du dataset...\n")
  df <- read.csv(chemin_dataset, stringsAsFactors = FALSE)
  df$Date <- as.POSIXct(df$Date)
  cat("✅ Dataset chargé:", nrow(df), "observations\n\n")
  return(df)
}

# =============================================================================
# GRAPHIQUE INTERACTIF DE CONSOMMATION
# =============================================================================

creer_graphique_interactif <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 CRÉATION DE GRAPHIQUES INTERACTIFS\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Échantillonner pour performance
  df_echantillon <- df %>%
    filter(!is.na(Date), !is.na(Consommation)) %>%
    arrange(Date) %>%
    slice(seq(1, n(), by = max(1, floor(n() / 20000))))
  
  # Graphique interactif consommation
  cat("📊 Création graphique interactif consommation...\n")
  
  p_interactif <- plot_ly(df_echantillon, 
                          x = ~Date, 
                          y = ~Consommation,
                          type = 'scatter',
                          mode = 'lines',
                          line = list(color = 'steelblue', width = 1),
                          name = 'Consommation') %>%
    layout(title = "Évolution de la Consommation (Interactif)",
           xaxis = list(title = "Date"),
           yaxis = list(title = "Consommation (MW)"))
  
  # Sauvegarder
  htmlwidgets::saveWidget(p_interactif, 
                          "figures/consommation_interactif.html",
                          selfcontained = TRUE)
  
  cat("   ✅ Graphique sauvegardé: figures/consommation_interactif.html\n\n")
  
  return(p_interactif)
}

# =============================================================================
# HEATMAP DE CONSOMMATION
# =============================================================================

creer_heatmap_consommation <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("🔥 CRÉATION DE HEATMAP\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  if (!"Heure" %in% colnames(df) || !"JourSemaine" %in% colnames(df)) {
    cat("⚠️ Variables Heure ou JourSemaine non disponibles\n\n")
    return(NULL)
  }
  
  # Préparer données pour heatmap
  heatmap_data <- df %>%
    filter(!is.na(Heure), !is.na(JourSemaine), !is.na(Consommation)) %>%
    mutate(JourNom = case_when(
      JourSemaine == 1 ~ "Dim",
      JourSemaine == 2 ~ "Lun",
      JourSemaine == 3 ~ "Mar",
      JourSemaine == 4 ~ "Mer",
      JourSemaine == 5 ~ "Jeu",
      JourSemaine == 6 ~ "Ven",
      JourSemaine == 7 ~ "Sam"
    )) %>%
    mutate(JourNom = factor(JourNom, 
                            levels = c("Lun", "Mar", "Mer", "Jeu", "Ven", "Sam", "Dim"))) %>%
    group_by(JourNom, Heure) %>%
    summarise(
      Consommation_moyenne = mean(Consommation, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Graphique heatmap
  p_heatmap <- heatmap_data %>%
    ggplot(aes(x = Heure, y = JourNom, fill = Consommation_moyenne)) +
    geom_tile() +
    scale_fill_viridis_c(name = "Consommation\n(MW)", option = "plasma") +
    labs(title = "Heatmap de Consommation par Jour et Heure",
         x = "Heure", y = "Jour de la Semaine") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 0))
  
  png("figures/heatmap_consommation.png", width = 1400, height = 600)
  print(p_heatmap)
  dev.off()
  
  cat("✅ Heatmap sauvegardée: figures/heatmap_consommation.png\n\n")
  
  return(p_heatmap)
}

# =============================================================================
# GRAPHIQUE MULTI-VARIABLES
# =============================================================================

creer_graphique_multi_variables <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 CRÉATION DE GRAPHIQUE MULTI-VARIABLES\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Échantillonner
  df_echantillon <- df %>%
    filter(!is.na(Date)) %>%
    arrange(Date) %>%
    slice(seq(1, n(), by = max(1, floor(n() / 10000))))
  
  # Créer graphique avec plusieurs variables
  plots <- list()
  
  # Consommation
  if ("Consommation" %in% colnames(df_echantillon)) {
    p1 <- ggplot(df_echantillon, aes(x = Date, y = Consommation)) +
      geom_line(color = "steelblue", alpha = 0.7) +
      labs(title = "Consommation", y = "MW") +
      theme_minimal() +
      theme(axis.title.x = element_blank())
    plots[["Consommation"]] <- p1
  }
  
  # Temperature
  if ("Temperature" %in% colnames(df_echantillon)) {
    p2 <- ggplot(df_echantillon, aes(x = Date, y = Temperature)) +
      geom_line(color = "red", alpha = 0.7) +
      labs(title = "Température", y = "°C") +
      theme_minimal() +
      theme(axis.title.x = element_blank())
    plots[["Temperature"]] <- p2
  }
  
  # Production RTE si disponible
  if ("RTE_Nucleaire" %in% colnames(df_echantillon)) {
    p3 <- ggplot(df_echantillon, aes(x = Date, y = RTE_Nucleaire)) +
      geom_line(color = "green", alpha = 0.7) +
      labs(title = "Production Nucléaire RTE", y = "MW") +
      theme_minimal() +
      theme(axis.title.x = element_blank())
    plots[["RTE_Nucleaire"]] <- p3
  }
  
  # Combiner
  if (length(plots) > 0) {
    png("figures/multi_variables.png", width = 1400, height = 400 * length(plots))
    do.call(grid.arrange, c(plots, ncol = 1))
    dev.off()
    
    cat("✅ Graphique multi-variables sauvegardé: figures/multi_variables.png\n\n")
  }
}

# =============================================================================
# GRAPHIQUE DE CORRÉLATION AVANCÉ
# =============================================================================

creer_graphique_correlation_avance <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 CRÉATION DE GRAPHIQUE DE CORRÉLATION AVANCÉ\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Variables à analyser
  vars <- c("Consommation", "Temperature", 
            "RTE_Nucleaire", "RTE_Eolien", "RTE_Solaire",
            "ImpactConsommation")
  vars_presentes <- vars[vars %in% colnames(df)]
  
  if (length(vars_presentes) < 2) {
    cat("⚠️ Pas assez de variables pour l'analyse\n\n")
    return(NULL)
  }
  
  # Échantillonner
  df_echantillon <- df %>%
    select(all_of(vars_presentes)) %>%
    sample_n(min(5000, nrow(df)))
  
  # Calculer corrélations
  cor_matrix <- cor(df_echantillon, use = "pairwise.complete.obs")
  
  # Convertir en format long
  cor_df <- as.data.frame(cor_matrix) %>%
    rownames_to_column(var = "Var1") %>%
    pivot_longer(-Var1, names_to = "Var2", values_to = "Correlation")
  
  # Graphique
  p_cor <- cor_df %>%
    ggplot(aes(x = Var1, y = Var2, fill = Correlation)) +
    geom_tile() +
    scale_fill_gradient2(low = "blue", mid = "white", high = "red",
                        midpoint = 0, limits = c(-1, 1)) +
    labs(title = "Matrice de Corrélations Avancée",
         x = "", y = "") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  png("figures/correlation_avance.png", width = 1000, height = 800)
  print(p_cor)
  dev.off()
  
  cat("✅ Graphique de corrélation sauvegardé: figures/correlation_avance.png\n\n")
}

# =============================================================================
# GRAPHIQUE DE DISTRIBUTION 3D
# =============================================================================

creer_graphique_3d <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 CRÉATION DE GRAPHIQUE 3D\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  if (!"Heure" %in% colnames(df) || !"Mois" %in% colnames(df)) {
    cat("⚠️ Variables nécessaires non disponibles\n\n")
    return(NULL)
  }
  
  # Préparer données
  data_3d <- df %>%
    filter(!is.na(Heure), !is.na(Mois), !is.na(Consommation)) %>%
    group_by(Heure, Mois) %>%
    summarise(
      Consommation_moyenne = mean(Consommation, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Graphique 3D interactif
  p_3d <- plot_ly(data_3d, 
                   x = ~Heure, 
                   y = ~Mois, 
                   z = ~Consommation_moyenne,
                   type = 'mesh3d',
                   colorscale = 'Viridis') %>%
    layout(scene = list(
      xaxis = list(title = "Heure"),
      yaxis = list(title = "Mois"),
      zaxis = list(title = "Consommation (MW)")
    ),
    title = "Consommation 3D par Heure et Mois")
  
  # Sauvegarder
  htmlwidgets::saveWidget(p_3d, 
                          "figures/consommation_3d.html",
                          selfcontained = TRUE)
  
  cat("✅ Graphique 3D sauvegardé: figures/consommation_3d.html\n\n")
  
  return(p_3d)
}

# =============================================================================
# DASHBOARD VISUEL
# =============================================================================

creer_dashboard_visuel <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 CRÉATION DE DASHBOARD VISUEL\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Créer plusieurs graphiques pour dashboard
  plots_dashboard <- list()
  
  # 1. Consommation par saison
  if ("Saison" %in% colnames(df)) {
    p1 <- df %>%
      filter(!is.na(Saison)) %>%
      ggplot(aes(x = Saison, y = Consommation, fill = Saison)) +
      geom_boxplot() +
      labs(title = "Consommation par Saison") +
      theme_minimal() +
      theme(legend.position = "none")
    plots_dashboard[["Saison"]] <- p1
  }
  
  # 2. Consommation par type de jour
  if ("TypeJour" %in% colnames(df)) {
    p2 <- df %>%
      filter(!is.na(TypeJour)) %>%
      ggplot(aes(x = TypeJour, y = Consommation, fill = TypeJour)) +
      geom_boxplot() +
      labs(title = "Consommation par Type de Jour") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1),
            legend.position = "none")
    plots_dashboard[["TypeJour"]] <- p2
  }
  
  # 3. Pattern horaire
  if ("Heure" %in% colnames(df)) {
    p3 <- df %>%
      filter(!is.na(Heure)) %>%
      group_by(Heure) %>%
      summarise(Consommation_moyenne = mean(Consommation, na.rm = TRUE)) %>%
      ggplot(aes(x = Heure, y = Consommation_moyenne)) +
      geom_line(color = "steelblue", size = 1.2) +
      geom_point(color = "red") +
      labs(title = "Pattern Horaire", x = "Heure", y = "Consommation (MW)") +
      theme_minimal()
    plots_dashboard[["Horaire"]] <- p3
  }
  
  # 4. Évolution temporelle
  if ("Annee" %in% colnames(df)) {
    p4 <- df %>%
      filter(!is.na(Annee)) %>%
      group_by(Annee) %>%
      summarise(Consommation_moyenne = mean(Consommation, na.rm = TRUE)) %>%
      ggplot(aes(x = Annee, y = Consommation_moyenne)) +
      geom_line(color = "steelblue", size = 1.2) +
      geom_point(color = "red") +
      labs(title = "Évolution Annuelle", x = "Année", y = "Consommation (MW)") +
      theme_minimal()
    plots_dashboard[["Evolution"]] <- p4
  }
  
  # Combiner en dashboard
  if (length(plots_dashboard) > 0) {
    png("figures/dashboard_visuel.png", 
        width = 1600, 
        height = 1200)
    
    if (length(plots_dashboard) == 4) {
      grid.arrange(plots_dashboard[[1]], plots_dashboard[[2]],
                   plots_dashboard[[3]], plots_dashboard[[4]],
                   ncol = 2)
    } else {
      do.call(grid.arrange, c(plots_dashboard, ncol = 2))
    }
    
    dev.off()
    
    cat("✅ Dashboard sauvegardé: figures/dashboard_visuel.png\n\n")
  }
}

# =============================================================================
# FONCTION PRINCIPALE
# =============================================================================

creer_toutes_visualisations <- function() {
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  cat("🎨 CRÉATION DE VISUALISATIONS CRÉATIVES\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Installer packages si nécessaire
  if (!require("htmlwidgets", quietly = TRUE)) {
    install.packages("htmlwidgets", repos = "https://cran.rstudio.com/", quiet = TRUE)
    library(htmlwidgets)
  }
  
  if (!require("viridis", quietly = TRUE)) {
    install.packages("viridis", repos = "https://cran.rstudio.com/", quiet = TRUE)
    library(viridis)
  }
  
  # Charger les données
  df <- charger_dataset()
  
  # 1. Graphique interactif
  p_interactif <- creer_graphique_interactif(df)
  
  # 2. Heatmap
  p_heatmap <- creer_heatmap_consommation(df)
  
  # 3. Multi-variables
  creer_graphique_multi_variables(df)
  
  # 4. Corrélation avancée
  creer_graphique_correlation_avance(df)
  
  # 5. Graphique 3D
  p_3d <- creer_graphique_3d(df)
  
  # 6. Dashboard
  creer_dashboard_visuel(df)
  
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("✅ VISUALISATIONS CRÉATIVES TERMINÉES\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  cat("📁 Fichiers créés:\n")
  cat("   - figures/consommation_interactif.html\n")
  cat("   - figures/heatmap_consommation.png\n")
  cat("   - figures/multi_variables.png\n")
  cat("   - figures/correlation_avance.png\n")
  cat("   - figures/consommation_3d.html\n")
  cat("   - figures/dashboard_visuel.png\n\n")
  
  return(list(
    p_interactif = p_interactif,
    p_heatmap = p_heatmap,
    p_3d = p_3d
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
  
  resultats <- creer_toutes_visualisations()
}

