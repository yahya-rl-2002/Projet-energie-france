# =============================================================================
# ÉVALUATION DES PRÉVISIONS
# =============================================================================
# Évaluation détaillée de la qualité des prévisions avec métriques avancées

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
# CALCULER TOUTES LES MÉTRIQUES
# =============================================================================

calculer_metriques_completes <- function(observations, predictions, lower = NULL, upper = NULL) {
  valid <- !is.na(observations) & !is.na(predictions) & 
           is.finite(observations) & is.finite(predictions)
  obs <- observations[valid]
  pred <- predictions[valid]
  
  if (length(obs) == 0 || length(pred) == 0) {
    return(NULL)
  }
  
  # Métriques de base
  rmse <- sqrt(mean((obs - pred)^2))
  mae <- mean(abs(obs - pred))
  mape <- mean(abs((obs - pred) / obs)) * 100
  mse <- mean((obs - pred)^2)
  
  # R²
  ss_res <- sum((obs - pred)^2)
  ss_tot <- sum((obs - mean(obs))^2)
  r_squared <- 1 - (ss_res / ss_tot)
  
  # MASE
  if (length(obs) > 1) {
    naive_errors <- abs(diff(obs))
    mase_denom <- mean(naive_errors)
    mase <- ifelse(mase_denom > 0, mae / mase_denom, NA)
  } else {
    mase <- NA
  }
  
  # sMAPE
  smape <- mean(200 * abs(obs - pred) / (abs(obs) + abs(pred)), na.rm = TRUE)
  
  # Directional Accuracy
  if (length(obs) > 1 && length(pred) > 1) {
    obs_dir <- sign(diff(obs))
    pred_dir <- sign(diff(pred))
    da <- mean(obs_dir == pred_dir, na.rm = TRUE) * 100
  } else {
    da <- NA
  }
  
  # Theil's U
  if (length(obs) > 1) {
    theil_u <- sqrt(mean((obs - pred)^2)) / 
               (sqrt(mean(obs^2)) + sqrt(mean(pred^2)))
  } else {
    theil_u <- NA
  }
  
  # Couverture des intervalles (si fournis)
  couverture_80 <- NA
  couverture_95 <- NA
  
  if (!is.null(lower) && !is.null(upper)) {
    if (ncol(lower) >= 1) {
      dans_80 <- obs >= lower[, 1] & obs <= upper[, 1]
      couverture_80 <- mean(dans_80, na.rm = TRUE) * 100
    }
    if (ncol(lower) >= 2) {
      dans_95 <- obs >= lower[, 2] & obs <= upper[, 2]
      couverture_95 <- mean(dans_95, na.rm = TRUE) * 100
    }
  }
  
  return(list(
    RMSE = rmse,
    MAE = mae,
    MAPE = mape,
    MSE = mse,
    R_squared = r_squared,
    MASE = mase,
    sMAPE = smape,
    Directional_Accuracy = da,
    Theil_U = theil_u,
    Couverture_80 = couverture_80,
    Couverture_95 = couverture_95
  ))
}

# =============================================================================
# ÉVALUER PRÉVISIONS PAR HORIZON
# =============================================================================

evaluer_par_horizon <- function(train_ts, test_ts, modele, horizons = c(1, 6, 12, 24, 48, 72)) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 ÉVALUATION PAR HORIZON\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  resultats <- list()
  
  for (h in horizons) {
    if (h > length(test_ts)) {
      cat("⚠️ Horizon", h, "trop grand, ignoré\n\n")
      next
    }
    
    cat("📊 Horizon:", h, "pas...\n")
    
    # Prévoir
    prev <- forecast(modele, h = h, level = c(80, 95))
    prev_mean <- as.numeric(prev$mean[1:h])
    test_h <- as.numeric(test_ts[1:h])
    
    # Calculer métriques
    metrics <- calculer_metriques_completes(
      test_h, 
      prev_mean,
      prev$lower,
      prev$upper
    )
    
    if (!is.null(metrics)) {
      resultats[[paste0("h", h)]] <- data.frame(
        Horizon = h,
        RMSE = metrics$RMSE,
        MAE = metrics$MAE,
        MAPE = metrics$MAPE,
        R_squared = metrics$R_squared,
        MASE = metrics$MASE,
        sMAPE = metrics$sMAPE,
        Directional_Accuracy = metrics$Directional_Accuracy,
        Theil_U = metrics$Theil_U,
        Couverture_80 = metrics$Couverture_80,
        Couverture_95 = metrics$Couverture_95
      )
      
      cat("   ✅ RMSE:", round(metrics$RMSE, 2), 
          "- MAPE:", round(metrics$MAPE, 2), "%\n")
    }
    
    cat("\n")
  }
  
  if (length(resultats) > 0) {
    resultats_df <- do.call(rbind, resultats)
    return(resultats_df)
  }
  
  return(NULL)
}

# =============================================================================
# VISUALISER ÉVALUATION
# =============================================================================

visualiser_evaluation <- function(resultats_horizon) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 CRÉATION DES GRAPHIQUES D'ÉVALUATION\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  if (is.null(resultats_horizon)) {
    cat("⚠️ Aucun résultat à visualiser\n\n")
    return()
  }
  
  # Graphique RMSE par horizon
  p1 <- ggplot(resultats_horizon, aes(x = Horizon, y = RMSE)) +
    geom_line(size = 1.2, color = "blue") +
    geom_point(size = 2, color = "blue") +
    labs(title = "RMSE par Horizon",
         x = "Horizon (pas)", y = "RMSE") +
    theme_minimal()
  
  # Graphique MAPE par horizon
  p2 <- ggplot(resultats_horizon, aes(x = Horizon, y = MAPE)) +
    geom_line(size = 1.2, color = "red") +
    geom_point(size = 2, color = "red") +
    labs(title = "MAPE par Horizon",
         x = "Horizon (pas)", y = "MAPE (%)") +
    theme_minimal()
  
  # Graphique R² par horizon
  p3 <- ggplot(resultats_horizon, aes(x = Horizon, y = R_squared)) +
    geom_line(size = 1.2, color = "green") +
    geom_point(size = 2, color = "green") +
    labs(title = "R² par Horizon",
         x = "Horizon (pas)", y = "R²") +
    theme_minimal()
  
  # Graphique couverture par horizon
  p4 <- ggplot(resultats_horizon, aes(x = Horizon)) +
    geom_line(aes(y = Couverture_95, color = "95%"), size = 1.2) +
    geom_line(aes(y = Couverture_80, color = "80%"), size = 1.2) +
    geom_hline(yintercept = 95, linetype = "dashed", color = "red") +
    geom_hline(yintercept = 80, linetype = "dashed", color = "orange") +
    labs(title = "Couverture des Intervalles par Horizon",
         x = "Horizon (pas)", y = "Couverture (%)",
         color = "Niveau") +
    theme_minimal() +
    scale_color_manual(values = c("95%" = "blue", "80%" = "orange"))
  
  # Combiner graphiques
  png("figures/evaluation_previsions.png", width = 1600, height = 1600)
  grid.arrange(p1, p2, p3, p4, ncol = 2)
  dev.off()
  
  cat("✅ Graphiques sauvegardés: figures/evaluation_previsions.png\n\n")
}

# =============================================================================
# EXPORTER ÉVALUATION
# =============================================================================

exporter_evaluation <- function(resultats_horizon) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("💾 EXPORTATION DE L'ÉVALUATION\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  if (!dir.exists("data")) {
    dir.create("data", recursive = TRUE)
  }
  
  if (!is.null(resultats_horizon)) {
    write.csv(resultats_horizon, get_path_previsions("evaluation_previsions.csv"), row.names = FALSE)
    
    cat("✅ Évaluation sauvegardée:", get_path_previsions("evaluation_previsions.csv"), "\n")
    cat("   Total:", nrow(resultats_horizon), "horizons évalués\n\n")
    
    # Afficher résumé
    cat("📊 RÉSUMÉ DE L'ÉVALUATION:\n\n")
    print(resultats_horizon)
    cat("\n")
    
    return(resultats_horizon)
  }
  
  return(NULL)
}

# =============================================================================
# FONCTION PRINCIPALE
# =============================================================================

executer_evaluation_previsions <- function() {
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 ÉVALUATION DES PRÉVISIONS\n")
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
  
  # Diviser train/test
  train_size <- floor(length(consommation_ts) * 0.8)
  train_ts <- ts(consommation_ts[1:train_size], frequency = frequency(consommation_ts))
  test_ts <- consommation_ts[(train_size + 1):length(consommation_ts)]
  
  cat("📊 Train:", length(train_ts), "observations\n")
  cat("📊 Test:", length(test_ts), "observations\n\n")
  
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
  
  # Évaluer par horizon
  horizons <- c(1, 6, 12, 24, 48, 72)
  resultats_horizon <- evaluer_par_horizon(train_ts, test_ts, modele, horizons)
  
  # Visualiser
  visualiser_evaluation(resultats_horizon)
  
  # Exporter
  resultats_df <- exporter_evaluation(resultats_horizon)
  
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("✅ ÉVALUATION DES PRÉVISIONS TERMINÉE\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  cat("📁 Fichiers créés:\n")
  cat("   - figures/evaluation_previsions.png\n")
  cat("   - data/evaluation_previsions.csv\n\n")
  
  return(list(
    modele = modele,
    resultats = resultats_df
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
  fichier_log <- paste0("logs/evaluation_previsions_", timestamp, ".log")
  
  sink(fichier_log, split = TRUE)
  
  cat("=", paste0(rep("=", 78), collapse = ""), "=\n", sep = "")
  cat("📝 LOG D'EXÉCUTION - ÉVALUATION DES PRÉVISIONS\n")
  cat("=", paste0(rep("=", 78), collapse = ""), "=\n", sep = "")
  cat("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
  cat("Script: evaluation_previsions.R\n\n")
  
  tryCatch({
    resultats <- executer_evaluation_previsions()
    
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

