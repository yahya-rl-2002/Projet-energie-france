# =============================================================================
# DÉTECTION D'ANOMALIES
# =============================================================================
# Détection des valeurs aberrantes et des jours exceptionnels

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
library(lubridate)
library(ggplot2)
library(plotly)

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
# DÉTECTION PAR MÉTHODE IQR (INTERQUARTILE RANGE)
# =============================================================================

detecter_anomalies_iqr <- function(df, variable = "Consommation") {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 DÉTECTION D'ANOMALIES PAR MÉTHODE IQR\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  if (!variable %in% colnames(df)) {
    cat("⚠️ Variable", variable, "non disponible\n\n")
    return(NULL)
  }
  
  valeurs <- df[[variable]][!is.na(df[[variable]])]
  
  if (length(valeurs) == 0) {
    cat("⚠️ Aucune valeur disponible\n\n")
    return(NULL)
  }
  
  # Calculer quartiles
  Q1 <- quantile(valeurs, 0.25, na.rm = TRUE)
  Q3 <- quantile(valeurs, 0.75, na.rm = TRUE)
  IQR <- Q3 - Q1
  
  # Seuils
  seuil_bas <- Q1 - 1.5 * IQR
  seuil_haut <- Q3 + 1.5 * IQR
  
  cat("📊 Statistiques:\n")
  cat("   Q1:", round(Q1, 2), "\n")
  cat("   Q3:", round(Q3, 2), "\n")
  cat("   IQR:", round(IQR, 2), "\n")
  cat("   Seuil bas:", round(seuil_bas, 2), "\n")
  cat("   Seuil haut:", round(seuil_haut, 2), "\n\n")
  
  # Identifier anomalies
  df$Anomalie_IQR <- ifelse(df[[variable]] < seuil_bas | df[[variable]] > seuil_haut, 
                            TRUE, FALSE)
  
  n_anomalies <- sum(df$Anomalie_IQR, na.rm = TRUE)
  pct_anomalies <- n_anomalies / nrow(df) * 100
  
  cat("🔍 Anomalies détectées:\n")
  cat("   Nombre:", n_anomalies, "\n")
  cat("   Pourcentage:", round(pct_anomalies, 2), "%\n\n")
  
  # Détails des anomalies
  anomalies <- df %>%
    filter(Anomalie_IQR == TRUE) %>%
    arrange(desc(!!sym(variable))) %>%
    select(Date, all_of(variable), Temperature, TypeJour, Couleur_TEMPO)
  
  cat("📊 Top 10 anomalies (valeurs élevées):\n\n")
  print(head(anomalies, 10))
  cat("\n")
  
  return(list(
    df = df,
    seuil_bas = seuil_bas,
    seuil_haut = seuil_haut,
    anomalies = anomalies
  ))
}

# =============================================================================
# DÉTECTION PAR MÉTHODE Z-SCORE
# =============================================================================

detecter_anomalies_zscore <- function(df, variable = "Consommation", seuil = 3) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 DÉTECTION D'ANOMALIES PAR Z-SCORE\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  if (!variable %in% colnames(df)) {
    cat("⚠️ Variable", variable, "non disponible\n\n")
    return(NULL)
  }
  
  valeurs <- df[[variable]][!is.na(df[[variable]])]
  
  if (length(valeurs) == 0) {
    cat("⚠️ Aucune valeur disponible\n\n")
    return(NULL)
  }
  
  # Calculer moyenne et écart-type
  moyenne <- mean(valeurs, na.rm = TRUE)
  ecart_type <- sd(valeurs, na.rm = TRUE)
  
  cat("📊 Statistiques:\n")
  cat("   Moyenne:", round(moyenne, 2), "\n")
  cat("   Écart-type:", round(ecart_type, 2), "\n")
  cat("   Seuil Z-score:", seuil, "\n\n")
  
  # Calculer Z-scores
  df$Z_Score <- abs((df[[variable]] - moyenne) / ecart_type)
  df$Anomalie_ZScore <- df$Z_Score > seuil
  
  n_anomalies <- sum(df$Anomalie_ZScore, na.rm = TRUE)
  pct_anomalies <- n_anomalies / nrow(df) * 100
  
  cat("🔍 Anomalies détectées:\n")
  cat("   Nombre:", n_anomalies, "\n")
  cat("   Pourcentage:", round(pct_anomalies, 2), "%\n\n")
  
  # Détails des anomalies
  anomalies <- df %>%
    filter(Anomalie_ZScore == TRUE) %>%
    arrange(desc(Z_Score)) %>%
    select(Date, all_of(variable), Z_Score, Temperature, TypeJour)
  
  cat("📊 Top 10 anomalies (Z-score le plus élevé):\n\n")
  print(head(anomalies, 10))
  cat("\n")
  
  return(list(
    df = df,
    moyenne = moyenne,
    ecart_type = ecart_type,
    anomalies = anomalies
  ))
}

# =============================================================================
# DÉTECTION DES PICS DE CONSOMMATION
# =============================================================================

detecter_pics_consommation <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 DÉTECTION DES PICS DE CONSOMMATION\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Définir seuil (percentile 95)
  seuil_pic <- quantile(df$Consommation, 0.95, na.rm = TRUE)
  
  cat("📊 Seuil pic (percentile 95):", round(seuil_pic, 2), "MW\n\n")
  
  # Identifier pics
  pics <- df %>%
    filter(Consommation >= seuil_pic) %>%
    mutate(Date_jour = as.Date(Date)) %>%
    group_by(Date_jour) %>%
    summarise(
      Consommation_max = max(Consommation, na.rm = TRUE),
      Consommation_moyenne = mean(Consommation, na.rm = TRUE),
      Nombre_heures_pic = n(),
      Temperature = mean(Temperature, na.rm = TRUE),
      TypeJour = first(TypeJour),
      Couleur_TEMPO = first(Couleur_TEMPO),
      .groups = "drop"
    ) %>%
    arrange(desc(Consommation_max))
  
  cat("📊 Jours avec pics de consommation:\n")
  cat("   Nombre de jours:", nrow(pics), "\n\n")
  
  print(head(pics, 20))
  cat("\n")
  
  # Analyser patterns des pics
  if (nrow(pics) > 0) {
    cat("📊 Analyse des patterns des pics:\n\n")
    
    # Par type de jour
    if ("TypeJour" %in% colnames(pics)) {
      pics_par_type <- pics %>%
        filter(!is.na(TypeJour)) %>%
        group_by(TypeJour) %>%
        summarise(
          Nombre_pics = n(),
          Consommation_max_moyenne = mean(Consommation_max, na.rm = TRUE),
          .groups = "drop"
        )
      print(pics_par_type)
      cat("\n")
    }
    
    # Par saison
    pics$Mois <- month(pics$Date_jour)
    pics$Saison <- case_when(
      pics$Mois %in% c(12, 1, 2) ~ "Hiver",
      pics$Mois %in% c(3, 4, 5) ~ "Printemps",
      pics$Mois %in% c(6, 7, 8) ~ "Été",
      pics$Mois %in% c(9, 10, 11) ~ "Automne"
    )
    
    pics_par_saison <- pics %>%
      filter(!is.na(Saison)) %>%
      group_by(Saison) %>%
      summarise(
        Nombre_pics = n(),
        Consommation_max_moyenne = mean(Consommation_max, na.rm = TRUE),
        .groups = "drop"
      )
    print(pics_par_saison)
    cat("\n")
  }
  
  return(pics)
}

# =============================================================================
# DÉTECTION DES VALEURS ABERRANTES PAR HEURE
# =============================================================================

detecter_anomalies_par_heure <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("🕐 DÉTECTION D'ANOMALIES PAR HEURE\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  if (!"Heure" %in% colnames(df)) {
    cat("⚠️ Variable Heure non disponible\n\n")
    return(NULL)
  }
  
  # Calculer statistiques par heure
  stats_heure <- df %>%
    filter(!is.na(Heure), !is.na(Consommation)) %>%
    group_by(Heure) %>%
    summarise(
      Consommation_moyenne = mean(Consommation, na.rm = TRUE),
      Consommation_sd = sd(Consommation, na.rm = TRUE),
      Consommation_min = min(Consommation, na.rm = TRUE),
      Consommation_max = max(Consommation, na.rm = TRUE),
      .groups = "drop"
    )
  
  # Identifier anomalies (valeurs > moyenne + 2*SD)
  df_avec_stats <- df %>%
    left_join(stats_heure, by = "Heure") %>%
    mutate(
      Seuil_haut = Consommation_moyenne + 2 * Consommation_sd,
      Seuil_bas = Consommation_moyenne - 2 * Consommation_sd,
      Anomalie_Heure = Consommation > Seuil_haut | Consommation < Seuil_bas
    )
  
  n_anomalies <- sum(df_avec_stats$Anomalie_Heure, na.rm = TRUE)
  cat("🔍 Anomalies détectées par heure:\n")
  cat("   Nombre:", n_anomalies, "\n")
  cat("   Pourcentage:", round(n_anomalies / nrow(df_avec_stats) * 100, 2), "%\n\n")
  
  # Anomalies par heure
  anomalies_par_heure <- df_avec_stats %>%
    filter(Anomalie_Heure == TRUE) %>%
    group_by(Heure) %>%
    summarise(
      Nombre_anomalies = n(),
      Consommation_max = max(Consommation, na.rm = TRUE),
      .groups = "drop"
    ) %>%
    arrange(desc(Nombre_anomalies))
  
  print(anomalies_par_heure)
  cat("\n")
  
  return(df_avec_stats)
}

# =============================================================================
# VISUALISATION DES ANOMALIES
# =============================================================================

visualiser_anomalies <- function(df, variable = "Consommation") {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 CRÉATION DES VISUALISATIONS\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Échantillonner pour le graphique
  df_echantillon <- df %>%
    filter(!is.na(Date), !is.na(!!sym(variable))) %>%
    arrange(Date) %>%
    slice(seq(1, n(), by = max(1, floor(n() / 20000))))
  
  # Graphique avec anomalies IQR
  if ("Anomalie_IQR" %in% colnames(df_echantillon)) {
    p_iqr <- ggplot(df_echantillon, aes(x = Date, y = !!sym(variable))) +
      geom_line(alpha = 0.3, color = "steelblue") +
      geom_point(data = df_echantillon %>% filter(Anomalie_IQR == TRUE),
                 aes(color = "Anomalie"), size = 1) +
      labs(title = "Détection d'Anomalies par Méthode IQR",
           x = "Date", y = variable,
           color = "Type") +
      theme_minimal() +
      scale_color_manual(values = c("Anomalie" = "red"))
    
    png("figures/anomalies_iqr.png", width = 1400, height = 600)
    print(p_iqr)
    dev.off()
    
    cat("✅ Graphique IQR sauvegardé: figures/anomalies_iqr.png\n")
  }
  
  # Graphique avec anomalies Z-Score
  if ("Anomalie_ZScore" %in% colnames(df_echantillon)) {
    p_zscore <- ggplot(df_echantillon, aes(x = Date, y = !!sym(variable))) +
      geom_line(alpha = 0.3, color = "steelblue") +
      geom_point(data = df_echantillon %>% filter(Anomalie_ZScore == TRUE),
                 aes(color = "Anomalie"), size = 1) +
      labs(title = "Détection d'Anomalies par Z-Score",
           x = "Date", y = variable,
           color = "Type") +
      theme_minimal() +
      scale_color_manual(values = c("Anomalie" = "red"))
    
    png("figures/anomalies_zscore.png", width = 1400, height = 600)
    print(p_zscore)
    dev.off()
    
    cat("✅ Graphique Z-Score sauvegardé: figures/anomalies_zscore.png\n")
  }
  
  # Boxplot par type de jour avec anomalies
  if ("TypeJour" %in% colnames(df) && "Anomalie_IQR" %in% colnames(df)) {
    p_boxplot <- df %>%
      filter(!is.na(TypeJour)) %>%
      ggplot(aes(x = TypeJour, y = Consommation, fill = Anomalie_IQR)) +
      geom_boxplot() +
      labs(title = "Distribution de la Consommation par Type de Jour (Anomalies)",
           x = "Type de Jour", y = "Consommation (MW)") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
      scale_fill_manual(values = c("FALSE" = "steelblue", "TRUE" = "red"),
                       labels = c("Normal", "Anomalie"))
    
    png("figures/boxplot_anomalies.png", width = 1200, height = 600)
    print(p_boxplot)
    dev.off()
    
    cat("✅ Boxplot sauvegardé: figures/boxplot_anomalies.png\n")
  }
  
  cat("\n")
}

# =============================================================================
# FONCTION PRINCIPALE
# =============================================================================

detecter_toutes_anomalies <- function() {
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  cat("🔍 DÉTECTION D'ANOMALIES\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Charger les données
  df <- charger_dataset()
  
  # 1. Détection IQR
  resultats_iqr <- detecter_anomalies_iqr(df)
  if (!is.null(resultats_iqr)) {
    df <- resultats_iqr$df
  }
  
  # 2. Détection Z-Score
  resultats_zscore <- detecter_anomalies_zscore(df)
  if (!is.null(resultats_zscore)) {
    df <- resultats_zscore$df
  }
  
  # 3. Détection pics
  pics <- detecter_pics_consommation(df)
  
  # 4. Détection par heure
  df_heure <- detecter_anomalies_par_heure(df)
  
  # 5. Visualisations
  visualiser_anomalies(df)
  
  # Sauvegarder résultats
  if (!dir.exists("data")) {
    dir.create("data", recursive = TRUE)
  }
  
  if (!is.null(pics)) {
    write.csv(pics, get_path_analyses("pics_consommation.csv"), row.names = FALSE)
    cat("✅ Pics sauvegardés:", get_path_analyses("pics_consommation.csv"), "\n")
  }
  
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("✅ DÉTECTION D'ANOMALIES TERMINÉE\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  cat("📁 Fichiers créés:\n")
  cat("   - figures/anomalies_iqr.png\n")
  cat("   - figures/anomalies_zscore.png\n")
  cat("   - figures/boxplot_anomalies.png\n")
  cat("   - data/pics_consommation.csv\n\n")
  
  return(list(
    df = df,
    resultats_iqr = resultats_iqr,
    resultats_zscore = resultats_zscore,
    pics = pics
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
  
  resultats <- detecter_toutes_anomalies()
}

