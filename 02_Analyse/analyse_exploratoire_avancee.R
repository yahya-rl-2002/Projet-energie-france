# =============================================================================
# ANALYSE EXPLORATOIRE AVANCÉE
# =============================================================================
# Analyses statistiques détaillées du dataset complet

# Configurer miroir CRAN pour éviter les prompts interactifs
options(repos = c(CRAN = "https://cran.rstudio.com/"))

library(tidyverse)
library(lubridate)
library(ggplot2)
library(gridExtra)

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
  
  # Convertir Date en POSIXct
  df$Date <- as.POSIXct(df$Date)
  
  cat("✅ Dataset chargé:", nrow(df), "observations,", ncol(df), "colonnes\n")
  
  return(df)
}

# =============================================================================
# STATISTIQUES DESCRIPTIVES DÉTAILLÉES
# =============================================================================

statistiques_descriptives <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 STATISTIQUES DESCRIPTIVES DÉTAILLÉES\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Variables numériques principales
  vars_numeriques <- c("Consommation", "Temperature", 
                       "Conso_totale_communes", "Emissions_CO2_EDF",
                       "RTE_Consommation", "RTE_Nucleaire", "RTE_Eolien",
                       "RTE_Solaire", "ImpactConsommation")
  
  vars_presentes <- vars_numeriques[vars_numeriques %in% colnames(df)]
  
  if (length(vars_presentes) > 0) {
    cat("📈 Statistiques des variables numériques principales:\n\n")
    
    stats <- df %>%
      select(all_of(vars_presentes)) %>%
      summarise_all(list(
        Moyenne = ~ mean(.x, na.rm = TRUE),
        Mediane = ~ median(.x, na.rm = TRUE),
        Ecart_type = ~ sd(.x, na.rm = TRUE),
        Min = ~ min(.x, na.rm = TRUE),
        Max = ~ max(.x, na.rm = TRUE),
        Q1 = ~ quantile(.x, 0.25, na.rm = TRUE),
        Q3 = ~ quantile(.x, 0.75, na.rm = TRUE)
      ))
    
    # Afficher de manière lisible
    for (var in vars_presentes) {
      cat("  ", var, ":\n")
      cat("    Moyenne:", round(mean(df[[var]], na.rm = TRUE), 2), "\n")
      cat("    Médiane:", round(median(df[[var]], na.rm = TRUE), 2), "\n")
      cat("    Écart-type:", round(sd(df[[var]], na.rm = TRUE), 2), "\n")
      cat("    Min:", round(min(df[[var]], na.rm = TRUE), 2), "\n")
      cat("    Max:", round(max(df[[var]], na.rm = TRUE), 2), "\n")
      cat("    Q1:", round(quantile(df[[var]], 0.25, na.rm = TRUE), 2), "\n")
      cat("    Q3:", round(quantile(df[[var]], 0.75, na.rm = TRUE), 2), "\n\n")
    }
  }
  
  # Statistiques par type de jour
  cat("📅 Statistiques par type de jour:\n\n")
  
  if ("TypeJour" %in% colnames(df)) {
    stats_type_jour <- df %>%
      filter(!is.na(TypeJour)) %>%
      group_by(TypeJour) %>%
      summarise(
        Consommation_moyenne = mean(Consommation, na.rm = TRUE),
        Consommation_mediane = median(Consommation, na.rm = TRUE),
        Nombre_observations = n(),
        .groups = "drop"
      ) %>%
      arrange(desc(Consommation_moyenne))
    
    print(stats_type_jour)
    cat("\n")
  }
  
  # Statistiques par saison
  if ("Saison" %in% colnames(df)) {
    cat("🌍 Statistiques par saison:\n\n")
    
    stats_saison <- df %>%
      filter(!is.na(Saison)) %>%
      group_by(Saison) %>%
      summarise(
        Consommation_moyenne = mean(Consommation, na.rm = TRUE),
        Temperature_moyenne = mean(Temperature, na.rm = TRUE),
        Nombre_observations = n(),
        .groups = "drop"
      ) %>%
      arrange(Consommation_moyenne)
    
    print(stats_saison)
    cat("\n")
  }
  
  return(list(
    stats_numeriques = stats,
    stats_type_jour = if(exists("stats_type_jour")) stats_type_jour else NULL,
    stats_saison = if(exists("stats_saison")) stats_saison else NULL
  ))
}

# =============================================================================
# DISTRIBUTION DES VARIABLES
# =============================================================================

analyser_distributions <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 ANALYSE DES DISTRIBUTIONS\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Distribution de la consommation
  cat("📈 Distribution de la consommation:\n")
  cat("   Skewness:", round(moments::skewness(df$Consommation, na.rm = TRUE), 3), "\n")
  cat("   Kurtosis:", round(moments::kurtosis(df$Consommation, na.rm = TRUE), 3), "\n")
  
  # Test de normalité (Shapiro-Wilk sur échantillon)
  if (nrow(df) > 5000) {
    echantillon <- sample(df$Consommation[!is.na(df$Consommation)], 5000)
  } else {
    echantillon <- df$Consommation[!is.na(df$Consommation)]
  }
  
  test_norm <- shapiro.test(echantillon)
  cat("   Test de normalité (Shapiro-Wilk):\n")
  cat("     p-value:", format(test_norm$p.value, scientific = TRUE), "\n")
  cat("     Conclusion:", ifelse(test_norm$p.value < 0.05, "Distribution non normale", "Distribution normale"), "\n\n")
  
  # Graphiques de distribution
  cat("📊 Création des graphiques de distribution...\n")
  
  # Histogramme consommation
  p1 <- ggplot(df, aes(x = Consommation)) +
    geom_histogram(bins = 50, fill = "steelblue", alpha = 0.7) +
    labs(title = "Distribution de la Consommation",
         x = "Consommation (MW)", y = "Fréquence") +
    theme_minimal()
  
  # Boxplot par type de jour
  if ("TypeJour" %in% colnames(df)) {
    p2 <- df %>%
      filter(!is.na(TypeJour)) %>%
      ggplot(aes(x = TypeJour, y = Consommation, fill = TypeJour)) +
      geom_boxplot() +
      labs(title = "Consommation par Type de Jour",
           x = "Type de Jour", y = "Consommation (MW)") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1))
  } else {
    p2 <- ggplot() + theme_void()
  }
  
  # Sauvegarder
  png("figures/distributions_consommation.png", width = 1200, height = 800)
  grid.arrange(p1, p2, ncol = 2)
  dev.off()
  
  cat("   ✅ Graphiques sauvegardés: figures/distributions_consommation.png\n\n")
}

# =============================================================================
# ANALYSE DES TENDANCES
# =============================================================================

analyser_tendances <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📈 ANALYSE DES TENDANCES\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Tendance annuelle
  if ("Annee" %in% colnames(df)) {
    cat("📅 Évolution annuelle:\n\n")
    
    tendance_annuelle <- df %>%
      filter(!is.na(Annee), !is.na(Consommation)) %>%
      group_by(Annee) %>%
      summarise(
        Consommation_moyenne = mean(Consommation, na.rm = TRUE),
        Consommation_totale = sum(Consommation, na.rm = TRUE),
        Nombre_observations = n(),
        .groups = "drop"
      ) %>%
      arrange(Annee)
    
    print(tendance_annuelle)
    
    # Calculer taux de croissance
    if (nrow(tendance_annuelle) > 1) {
      croissance <- (tendance_annuelle$Consommation_moyenne[nrow(tendance_annuelle)] - 
                     tendance_annuelle$Consommation_moyenne[1]) / 
                    tendance_annuelle$Consommation_moyenne[1] * 100
      cat("\n   📊 Taux de croissance global:", round(croissance, 2), "%\n\n")
    }
  }
  
  # Tendance mensuelle
  if ("Mois" %in% colnames(df)) {
    cat("📅 Évolution mensuelle (moyenne):\n\n")
    
    tendance_mensuelle <- df %>%
      filter(!is.na(Mois), !is.na(Consommation)) %>%
      group_by(Mois) %>%
      summarise(
        Consommation_moyenne = mean(Consommation, na.rm = TRUE),
        Nombre_observations = n(),
        .groups = "drop"
      ) %>%
      arrange(Mois)
    
    print(tendance_mensuelle)
    cat("\n")
  }
  
  # Graphique de tendance
  cat("📊 Création du graphique de tendance...\n")
  
  # Échantillonner pour le graphique (trop de points sinon)
  df_echantillon <- df %>%
    filter(!is.na(Date), !is.na(Consommation)) %>%
    arrange(Date) %>%
    slice(seq(1, n(), by = max(1, floor(n() / 10000))))  # ~10000 points max
  
  p_tendance <- ggplot(df_echantillon, aes(x = Date, y = Consommation)) +
    geom_line(alpha = 0.3, color = "steelblue") +
    geom_smooth(method = "loess", span = 0.1, color = "red", se = TRUE) +
    labs(title = "Évolution de la Consommation dans le Temps",
         x = "Date", y = "Consommation (MW)") +
    theme_minimal()
  
  png("figures/tendance_consommation.png", width = 1400, height = 600)
  print(p_tendance)
  dev.off()
  
  cat("   ✅ Graphique sauvegardé: figures/tendance_consommation.png\n\n")
  
  return(list(
    tendance_annuelle = if(exists("tendance_annuelle")) tendance_annuelle else NULL,
    tendance_mensuelle = if(exists("tendance_mensuelle")) tendance_mensuelle else NULL
  ))
}

# =============================================================================
# IDENTIFICATION DES PÉRIODES CLÉS
# =============================================================================

identifier_periodes_cles <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("🔍 IDENTIFICATION DES PÉRIODES CLÉS\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Jours avec consommation maximale
  cat("📊 Top 10 jours avec consommation maximale:\n\n")
  
  top_consommation <- df %>%
    filter(!is.na(Consommation), !is.na(Date)) %>%
    mutate(Date_jour = as.Date(Date)) %>%
    group_by(Date_jour) %>%
    summarise(
      Consommation_max = max(Consommation, na.rm = TRUE),
      Consommation_moyenne = mean(Consommation, na.rm = TRUE),
      TypeJour = first(TypeJour),
      Couleur_TEMPO = first(Couleur_TEMPO),
      Temperature = mean(Temperature, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(desc(Consommation_max)) %>%
    head(10)
  
  print(top_consommation)
  cat("\n")
  
  # Jours avec consommation minimale
  cat("📊 Top 10 jours avec consommation minimale:\n\n")
  
  min_consommation <- df %>%
    filter(!is.na(Consommation), !is.na(Date)) %>%
    mutate(Date_jour = as.Date(Date)) %>%
    group_by(Date_jour) %>%
    summarise(
      Consommation_min = min(Consommation, na.rm = TRUE),
      Consommation_moyenne = mean(Consommation, na.rm = TRUE),
      TypeJour = first(TypeJour),
      Couleur_TEMPO = first(Couleur_TEMPO),
      Temperature = mean(Temperature, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(Consommation_min) %>%
    head(10)
  
  print(min_consommation)
  cat("\n")
  
  # Périodes avec pics de consommation
  cat("📊 Analyse des pics de consommation:\n\n")
  
  # Définir un seuil (percentile 95)
  seuil_pic <- quantile(df$Consommation, 0.95, na.rm = TRUE)
  
  pics <- df %>%
    filter(Consommation >= seuil_pic) %>%
    mutate(Date_jour = as.Date(Date)) %>%
    group_by(Date_jour) %>%
    summarise(
      Nombre_pics = n(),
      Consommation_max = max(Consommation, na.rm = TRUE),
      TypeJour = first(TypeJour),
      Couleur_TEMPO = first(Couleur_TEMPO),
      .groups = "drop"
    ) %>%
    arrange(desc(Nombre_pics)) %>%
    head(20)
  
  cat("   Seuil pic (percentile 95):", round(seuil_pic, 2), "MW\n")
  cat("   Nombre total de pics:", nrow(pics), "jours\n\n")
  print(head(pics, 10))
  cat("\n")
  
  return(list(
    top_consommation = top_consommation,
    min_consommation = min_consommation,
    pics = pics
  ))
}

# =============================================================================
# FONCTION PRINCIPALE
# =============================================================================

analyser_dataset_complet <- function() {
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  cat("🔬 ANALYSE EXPLORATOIRE AVANCÉE\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Charger les données
  df <- charger_dataset()
  
  # Installer package moments si nécessaire
  if (!require("moments", quietly = TRUE)) {
    install.packages("moments", repos = "https://cran.rstudio.com/", quiet = TRUE)
    library(moments)
  }
  
  # 1. Statistiques descriptives
  stats <- statistiques_descriptives(df)
  
  # 2. Distributions
  analyser_distributions(df)
  
  # 3. Tendances
  tendances <- analyser_tendances(df)
  
  # 4. Périodes clés
  periodes <- identifier_periodes_cles(df)
  
  # Sauvegarder les résultats dans la nouvelle structure
  # Sauvegarder statistiques
  if (!is.null(stats$stats_type_jour)) {
    write.csv(stats$stats_type_jour, 
              get_path_analyses("stats_par_type_jour.csv"), 
              row.names = FALSE)
  }
  
  if (!is.null(stats$stats_saison)) {
    write.csv(stats$stats_saison, 
              get_path_analyses("stats_par_saison.csv"), 
              row.names = FALSE)
  }
  
  if (!is.null(tendances$tendance_annuelle)) {
    write.csv(tendances$tendance_annuelle, 
              get_path_analyses("tendance_annuelle.csv"), 
              row.names = FALSE)
  }
  
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("✅ ANALYSE EXPLORATOIRE TERMINÉE\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  cat("📁 Fichiers créés:\n")
  cat("   - figures/distributions_consommation.png\n")
  cat("   - figures/tendance_consommation.png\n")
  cat("   -", get_path_analyses("stats_par_type_jour.csv"), "\n")
  cat("   -", get_path_analyses("stats_par_saison.csv"), "\n")
  cat("   -", get_path_analyses("tendance_annuelle.csv"), "\n\n")
  
  return(list(
    dataset = df,
    stats = stats,
    tendances = tendances,
    periodes = periodes
  ))
}

# =============================================================================
# EXÉCUTION
# =============================================================================

if (!interactive()) {
  # Changer vers le bon répertoire
  projet_dir <- "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION"
  if (dir.exists(projet_dir)) {
    setwd(projet_dir)
  }
  
  resultats <- analyser_dataset_complet()
}

