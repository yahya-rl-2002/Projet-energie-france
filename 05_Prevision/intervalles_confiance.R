# =============================================================================
# INTERVALLES DE CONFIANCE DES PRÉVISIONS
# =============================================================================
# Analyse détaillée des intervalles de confiance pour différentes probabilités

library(tidyverse)
library(forecast)
library(tseries)
library(ggplot2)
library(gridExtra)
library(lubridate)

# Configurer miroir CRAN
options(repos = c(CRAN = "https://cran.rstudio.com/"))

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
  stop("❌ Fichier chemins_resultats.R non trouvé. Vérifiez que le fichier existe dans 00_Utilitaires/")
}

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
  df <- df %>%
    filter(!is.na(Consommation), !is.na(Date)) %>%
    arrange(Date)
  cat("✅ Dataset chargé:", nrow(df), "observations\n\n")
  return(df)
}

# =============================================================================
# GÉNÉRER PRÉVISIONS AVEC INTERVALLES MULTIPLES
# =============================================================================

generer_previsions_intervalles <- function(modele, niveaux = c(50, 80, 90, 95, 99), horizon = 168) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 GÉNÉRATION DE PRÉVISIONS AVEC INTERVALLES MULTIPLES\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  cat("📊 Niveaux de confiance:", paste(niveaux, collapse = "%, "), "%\n")
  cat("📊 Horizon:", horizon, "pas\n\n")
  
  # Générer prévision avec tous les niveaux
  prev <- forecast(modele, h = horizon, level = niveaux)
  
  # Extraire les données
  resultats <- list(
    mean = as.numeric(prev$mean),
    niveaux = niveaux,
    lower = prev$lower,
    upper = prev$upper
  )
  
  cat("✅ Prévisions générées\n\n")
  
  return(resultats)
}

# =============================================================================
# ANALYSER LARGUEUR DES INTERVALLES
# =============================================================================

analyser_largeur_intervalles <- function(previsions_intervalles) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📏 ANALYSE DE LA LARGUEUR DES INTERVALLES\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  resultats <- list()
  
  for (i in 1:length(previsions_intervalles$niveaux)) {
    niveau <- previsions_intervalles$niveaux[i]
    
    largeur <- previsions_intervalles$upper[, i] - previsions_intervalles$lower[, i]
    
    resultats[[paste0("niveau_", niveau)]] <- data.frame(
      Niveau = niveau,
      Largeur_moyenne = mean(largeur, na.rm = TRUE),
      Largeur_mediane = median(largeur, na.rm = TRUE),
      Largeur_min = min(largeur, na.rm = TRUE),
      Largeur_max = max(largeur, na.rm = TRUE),
      Largeur_sd = sd(largeur, na.rm = TRUE)
    )
    
    cat("📊 Niveau", niveau, "%:\n")
    cat("   Largeur moyenne:", round(mean(largeur, na.rm = TRUE), 2), "\n")
    cat("   Largeur médiane:", round(median(largeur, na.rm = TRUE), 2), "\n")
    cat("   Largeur min:", round(min(largeur, na.rm = TRUE), 2), "\n")
    cat("   Largeur max:", round(max(largeur, na.rm = TRUE), 2), "\n\n")
  }
  
  largeur_df <- do.call(rbind, resultats)
  
  return(largeur_df)
}

# =============================================================================
# VISUALISER INTERVALLES DE CONFIANCE
# =============================================================================

visualiser_intervalles_confiance <- function(train_ts, previsions_intervalles, horizon_afficher = 168) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 CRÉATION DES GRAPHIQUES D'INTERVALLES DE CONFIANCE\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Prendre les dernières observations pour contexte
  n_context <- min(200, length(train_ts))
  train_recent <- tail(train_ts, n_context)
  
  freq <- frequency(train_ts)
  dernier_index <- time(train_ts)[length(train_ts)]
  
  # Données historiques
  hist_time <- tail(time(train_ts), n_context)
  hist_values <- as.numeric(train_recent)
  
  # Prévisions
  prev_time <- seq(from = dernier_index + 1/freq, by = 1/freq, length.out = horizon_afficher)
  prev_values <- previsions_intervalles$mean[1:horizon_afficher]
  
  # Créer dataframe pour ggplot
  df_plot <- data.frame(
    Time = c(hist_time, prev_time),
    Value = c(hist_values, prev_values),
    Type = c(rep("Historique", length(hist_values)), rep("Prévision", horizon_afficher))
  )
  
  # Ajouter intervalles pour chaque niveau
  for (i in 1:length(previsions_intervalles$niveaux)) {
    niveau <- previsions_intervalles$niveaux[i]
    lower <- previsions_intervalles$lower[1:horizon_afficher, i]
    upper <- previsions_intervalles$upper[1:horizon_afficher, i]
    
    df_plot[[paste0("Lower_", niveau)]] <- c(rep(NA, length(hist_values)), lower)
    df_plot[[paste0("Upper_", niveau)]] <- c(rep(NA, length(hist_values)), upper)
  }
  
  # Graphique principal avec tous les intervalles
  p <- ggplot(df_plot, aes(x = Time)) +
    geom_line(aes(y = Value, color = "Historique"), size = 1) +
    geom_vline(xintercept = dernier_index, linetype = "dashed", color = "gray")
  
  # Couleurs pour les intervalles (du plus large au plus étroit)
  couleurs_intervalles <- c(
    "99" = "red",
    "95" = "orange",
    "90" = "yellow",
    "80" = "lightblue",
    "50" = "blue"
  )
  
  # Ajouter intervalles du plus large au plus étroit
  niveaux_ordre <- sort(previsions_intervalles$niveaux, decreasing = TRUE)
  
  for (niveau in niveaux_ordre) {
    if (niveau %in% previsions_intervalles$niveaux) {
      col_lower <- paste0("Lower_", niveau)
      col_upper <- paste0("Upper_", niveau)
      
      p <- p +
        geom_ribbon(aes_string(ymin = col_lower, ymax = col_upper),
                   alpha = 0.2, fill = couleurs_intervalles[as.character(niveau)])
    }
  }
  
  # Ajouter ligne de prévision
  p <- p +
    geom_line(aes(y = Value, color = "Prévision"), size = 1.2, linetype = "dashed") +
    labs(
      title = "Prévisions avec Intervalles de Confiance Multiples",
      subtitle = paste("Horizon:", horizon_afficher, "h"),
      x = "Temps",
      y = "Consommation",
      color = "Type"
    ) +
    theme_minimal() +
    scale_color_manual(values = c("Historique" = "black", "Prévision" = "blue")) +
    theme(legend.position = "bottom")
  
  # Sauvegarder
  png("figures/intervalles_confiance_multiples.png", width = 1600, height = 900)
  print(p)
  dev.off()
  
  cat("✅ Graphique sauvegardé: figures/intervalles_confiance_multiples.png\n\n")
  
  # Graphique de la largeur des intervalles par niveau
  largeur_df <- analyser_largeur_intervalles(previsions_intervalles)
  
  p_largeur <- ggplot(largeur_df, aes(x = factor(Niveau), y = Largeur_moyenne, fill = factor(Niveau))) +
    geom_bar(stat = "identity") +
    geom_errorbar(aes(ymin = Largeur_moyenne - Largeur_sd, 
                     ymax = Largeur_moyenne + Largeur_sd),
                 width = 0.2) +
    labs(
      title = "Largeur Moyenne des Intervalles de Confiance",
      x = "Niveau de Confiance (%)",
      y = "Largeur Moyenne",
      fill = "Niveau"
    ) +
    theme_minimal() +
    scale_fill_brewer(palette = "YlOrRd")
  
  png("figures/largeur_intervalles.png", width = 1200, height = 600)
  print(p_largeur)
  dev.off()
  
  cat("✅ Graphique de largeur sauvegardé: figures/largeur_intervalles.png\n\n")
  
  return(largeur_df)
}

# =============================================================================
# EXPORTER INTERVALLES
# =============================================================================

exporter_intervalles <- function(previsions_intervalles, horizon = 168) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("💾 EXPORTATION DES INTERVALLES DE CONFIANCE\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  if (!dir.exists("data")) {
    dir.create("data", recursive = TRUE)
  }
  
  # Créer dataframe avec toutes les prévisions et intervalles
  df_export <- data.frame(
    Horizon = 1:horizon,
    Prevision = previsions_intervalles$mean[1:horizon]
  )
  
  # Ajouter intervalles pour chaque niveau
  for (i in 1:length(previsions_intervalles$niveaux)) {
    niveau <- previsions_intervalles$niveaux[i]
    df_export[[paste0("Lower_", niveau)]] <- previsions_intervalles$lower[1:horizon, i]
    df_export[[paste0("Upper_", niveau)]] <- previsions_intervalles$upper[1:horizon, i]
  }
  
  # Sauvegarder
  write.csv(df_export, get_path_previsions("previsions_intervalles_confiance.csv"), row.names = FALSE)
  
  cat("✅ Intervalles sauvegardés:", get_path_previsions("previsions_intervalles_confiance.csv"), "\n")
  cat("   Total:", nrow(df_export), "prévisions\n\n")
  
  return(df_export)
}

# =============================================================================
# FONCTION PRINCIPALE
# =============================================================================

executer_intervalles_confiance <- function() {
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 INTERVALLES DE CONFIANCE DES PRÉVISIONS\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Charger les données
  df <- charger_dataset()
  
  # Créer série temporelle
  consommation_ts <- ts(df$Consommation, 
                       frequency = 24,
                       start = c(year(min(df$Date)), yday(min(df$Date))))
  
  cat("📊 Série temporelle créée:\n")
  cat("   Observations:", length(consommation_ts), "\n")
  cat("   Fréquence:", frequency(consommation_ts), "h\n\n")
  
  # Échantillonner si nécessaire
  if (length(consommation_ts) > 50000) {
    cat("📊 Échantillonnage pour performance...\n")
    indices <- seq(1, length(consommation_ts), by = max(1, floor(length(consommation_ts) / 50000)))
    consommation_ts <- consommation_ts[indices]
    cat("   Taille après échantillonnage:", length(consommation_ts), "\n\n")
  }
  
  # Utiliser toutes les données pour l'entraînement
  train_ts <- consommation_ts
  
  # Charger le meilleur modèle
  chemin_comparaison <- "data/comparaison_modeles_finale.csv"
  nom_modele <- "ARIMA_auto"
  if (file.exists(chemin_comparaison)) {
    comparaison <- read.csv(chemin_comparaison)
    nom_modele <- comparaison$Modele[1]
    cat("📊 Utilisation du meilleur modèle:", nom_modele, "\n\n")
  }
  
  # Ajuster modèle
  cat("📊 Ajustement du modèle...\n")
  if (nom_modele == "TBATS") {
    modele <- tbats(train_ts)
  } else if (nom_modele == "ETS") {
    modele <- ets(train_ts)
  } else {
    modele <- auto.arima(train_ts, seasonal = TRUE, stepwise = TRUE)
  }
  cat("✅ Modèle ajusté\n\n")
  
  # Générer prévisions avec intervalles multiples
  niveaux <- c(50, 80, 90, 95, 99)
  horizon <- 168  # 1 semaine
  previsions_intervalles <- generer_previsions_intervalles(modele, niveaux, horizon)
  
  # Analyser largeur
  largeur_df <- analyser_largeur_intervalles(previsions_intervalles)
  
  # Visualiser
  visualiser_intervalles_confiance(train_ts, previsions_intervalles, horizon)
  
  # Exporter
  previsions_df <- exporter_intervalles(previsions_intervalles, horizon)
  
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("✅ ANALYSE DES INTERVALLES DE CONFIANCE TERMINÉE\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  cat("📁 Fichiers créés:\n")
  cat("   - figures/intervalles_confiance_multiples.png\n")
  cat("   - figures/largeur_intervalles.png\n")
  cat("   - data/previsions_intervalles_confiance.csv\n\n")
  
  return(list(
    modele = modele,
    previsions = previsions_intervalles,
    largeur = largeur_df,
    previsions_df = previsions_df
  ))
}

# =============================================================================
# EXÉCUTION
# =============================================================================

# Fonction pour exécuter avec sauvegarde des logs
executer_avec_logs <- function() {
  if (!dir.exists("logs")) {
    dir.create("logs", recursive = TRUE)
  }
  
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  fichier_log <- paste0("logs/intervalles_confiance_", timestamp, ".log")
  
  sink(fichier_log, split = TRUE)
  
  cat("=", paste0(rep("=", 78), collapse = ""), "=\n", sep = "")
  cat("📝 LOG D'EXÉCUTION - INTERVALLES DE CONFIANCE\n")
  cat("=", paste0(rep("=", 78), collapse = ""), "=\n", sep = "")
  cat("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
  cat("Script: intervalles_confiance.R\n\n")
  
  tryCatch({
    resultats <- executer_intervalles_confiance()
    
    cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
    cat("✅ EXÉCUTION TERMINÉE AVEC SUCCÈS\n")
    cat("📁 Log sauvegardé:", fichier_log, "\n")
    cat(paste0(rep("=", 80), collapse = ""), "\n\n")
    
    return(resultats)
  }, error = function(e) {
    cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
    cat("❌ ERREUR LORS DE L'EXÉCUTION:\n")
    cat(toString(e), "\n")
    cat(paste0(rep("=", 80), collapse = ""), "\n\n")
    stop(e)
  }, finally = {
    sink()
  })
}

# Exécuter automatiquement
projet_dir <- "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION"
if (dir.exists(projet_dir)) {
  setwd(projet_dir)
}

# Exécuter avec logs
resultats <- executer_avec_logs()

