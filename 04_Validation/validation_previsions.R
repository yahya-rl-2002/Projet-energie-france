# =============================================================================
# VALIDATION DES PRÉVISIONS
# =============================================================================
# Validation détaillée des prévisions avec métriques avancées

library(tidyverse)
library(forecast)
library(tseries)
library(ggplot2)
library(gridExtra)

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
# MÉTRIQUES DE VALIDATION AVANCÉES
# =============================================================================

calculer_metriques_avancees <- function(observations, predictions) {
  # Filtrer les valeurs valides
  valid <- !is.na(observations) & !is.na(predictions) & is.finite(observations) & is.finite(predictions)
  obs <- observations[valid]
  pred <- predictions[valid]
  
  if (length(obs) == 0 || length(pred) == 0) {
    return(NULL)
  }
  
  # Métriques de base
  rmse <- sqrt(mean((obs - pred)^2))
  mae <- mean(abs(obs - pred))
  mape <- mean(abs((obs - pred) / obs)) * 100
  
  # Métriques supplémentaires
  mse <- mean((obs - pred)^2)
  
  # R² (coefficient de détermination)
  ss_res <- sum((obs - pred)^2)
  ss_tot <- sum((obs - mean(obs))^2)
  r_squared <- 1 - (ss_res / ss_tot)
  
  # Mean Absolute Scaled Error (MASE)
  # Utiliser la moyenne naïve comme baseline
  if (length(obs) > 1) {
    naive_errors <- abs(diff(obs))
    mase_denom <- mean(naive_errors)
    if (mase_denom > 0) {
      mase <- mae / mase_denom
    } else {
      mase <- NA
    }
  } else {
    mase <- NA
  }
  
  # Symmetric MAPE (sMAPE)
  smape <- mean(200 * abs(obs - pred) / (abs(obs) + abs(pred)), na.rm = TRUE)
  
  # Directional Accuracy (DA)
  if (length(obs) > 1 && length(pred) > 1) {
    obs_dir <- sign(diff(obs))
    pred_dir <- sign(diff(pred))
    da <- mean(obs_dir == pred_dir, na.rm = TRUE) * 100
  } else {
    da <- NA
  }
  
  return(list(
    RMSE = rmse,
    MAE = mae,
    MAPE = mape,
    MSE = mse,
    R_squared = r_squared,
    MASE = mase,
    sMAPE = smape,
    Directional_Accuracy = da
  ))
}

# =============================================================================
# VALIDATION PAR HORIZON DE PRÉVISION
# =============================================================================

validation_par_horizon <- function(ts_data, horizons = c(1, 6, 12, 24, 48)) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 VALIDATION PAR HORIZON DE PRÉVISION\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  train_size <- floor(length(ts_data) * 0.8)
  train_data <- ts_data[1:train_size]
  test_data <- ts_data[(train_size + 1):length(ts_data)]
  
  freq <- frequency(ts_data)
  train_ts <- ts(train_data, frequency = freq)
  
  cat("📊 Train:", length(train_data), "observations\n")
  cat("📊 Test:", length(test_data), "observations\n\n")
  
  # Ajuster modèles
  modeles <- list()
  
  tryCatch({
    arima <- auto.arima(train_ts, seasonal = TRUE, stepwise = TRUE)
    modeles[["ARIMA"]] <- arima
  }, error = function(e) {
    cat("⚠️ Erreur ARIMA:", e$message, "\n")
  })
  
  tryCatch({
    ets_model <- ets(train_ts)
    modeles[["ETS"]] <- ets_model
  }, error = function(e) {
    cat("⚠️ Erreur ETS:", e$message, "\n")
  })
  
  # Évaluer pour chaque horizon
  resultats <- list()
  
  for (h in horizons) {
    if (h > length(test_data)) {
      cat("⚠️ Horizon", h, "trop grand, ignoré\n\n")
      next
    }
    
    cat("📊 Horizon:", h, "pas...\n")
    
    test_h <- test_data[1:h]
    
    for (nom_modele in names(modeles)) {
      tryCatch({
        prev <- forecast(modeles[[nom_modele]], h = h)
        prev_vals <- as.numeric(prev$mean[1:h])
        
        metrics <- calculer_metriques_avancees(test_h, prev_vals)
        
        if (!is.null(metrics)) {
          resultats[[paste0(nom_modele, "_h", h)]] <- data.frame(
            Modele = nom_modele,
            Horizon = h,
            RMSE = metrics$RMSE,
            MAE = metrics$MAE,
            MAPE = metrics$MAPE,
            R_squared = metrics$R_squared,
            MASE = metrics$MASE,
            sMAPE = metrics$sMAPE
          )
          
          cat("   ✅", nom_modele, "- RMSE:", round(metrics$RMSE, 2), 
              "- MAPE:", round(metrics$MAPE, 2), "%\n")
        }
      }, error = function(e) {
        cat("   ⚠️ Erreur:", e$message, "\n")
      })
    }
    
    cat("\n")
  }
  
  if (length(resultats) > 0) {
    resultats_df <- do.call(rbind, resultats)
    
    # Graphique RMSE par horizon
    p1 <- resultats_df %>%
      ggplot(aes(x = Horizon, y = RMSE, color = Modele)) +
      geom_line(size = 1.2) +
      geom_point(size = 2) +
      labs(title = "RMSE par Horizon de Prévision",
           x = "Horizon (pas)", y = "RMSE") +
      theme_minimal()
    
    # Graphique MAPE par horizon
    p2 <- resultats_df %>%
      ggplot(aes(x = Horizon, y = MAPE, color = Modele)) +
      geom_line(size = 1.2) +
      geom_point(size = 2) +
      labs(title = "MAPE par Horizon de Prévision",
           x = "Horizon (pas)", y = "MAPE (%)") +
      theme_minimal()
    
    png("figures/validation_par_horizon.png", width = 1400, height = 600)
    grid.arrange(p1, p2, ncol = 2)
    dev.off()
    
    cat("✅ Graphiques sauvegardés: figures/validation_par_horizon.png\n\n")
    
    print(resultats_df)
    cat("\n")
    
    return(resultats_df)
  }
  
  return(NULL)
}

# =============================================================================
# VALIDATION DES INTERVALLES DE CONFIANCE
# =============================================================================

validation_intervalles_confiance <- function(ts_data, niveau = 0.95) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 VALIDATION DES INTERVALLES DE CONFIANCE\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  train_size <- floor(length(ts_data) * 0.8)
  train_data <- ts_data[1:train_size]
  test_data <- ts_data[(train_size + 1):length(ts_data)]
  
  freq <- frequency(ts_data)
  train_ts <- ts(train_data, frequency = freq)
  
  h <- min(100, length(test_data))
  test_h <- test_data[1:h]
  
  # Ajuster modèles
  modeles <- list()
  
  tryCatch({
    arima <- auto.arima(train_ts, seasonal = TRUE, stepwise = TRUE)
    modeles[["ARIMA"]] <- arima
  }, error = function(e) {
    cat("⚠️ Erreur ARIMA:", e$message, "\n")
  })
  
  resultats <- list()
  
  for (nom_modele in names(modeles)) {
    cat("📊 Validation", nom_modele, "...\n")
    
    tryCatch({
      prev <- forecast(modeles[[nom_modele]], h = h, level = niveau * 100)
      
      prev_mean <- as.numeric(prev$mean[1:h])
      prev_lower <- as.numeric(prev$lower[1:h])
      prev_upper <- as.numeric(prev$upper[1:h])
      
      # Vérifier si les valeurs réelles sont dans l'intervalle
      dans_intervalle <- test_h >= prev_lower & test_h <= prev_upper
      couverture <- mean(dans_intervalle, na.rm = TRUE) * 100
      
      # Largeur moyenne de l'intervalle
      largeur_moyenne <- mean(prev_upper - prev_lower, na.rm = TRUE)
      
      resultats[[nom_modele]] <- data.frame(
        Modele = nom_modele,
        Niveau = niveau,
        Couverture_observee = couverture,
        Couverture_attendue = niveau * 100,
        Largeur_moyenne = largeur_moyenne,
        RMSE = sqrt(mean((test_h - prev_mean)^2, na.rm = TRUE))
      )
      
      cat("   Couverture observée:", round(couverture, 2), "%\n")
      cat("   Couverture attendue:", round(niveau * 100, 2), "%\n")
      cat("   Largeur moyenne:", round(largeur_moyenne, 2), "\n\n")
    }, error = function(e) {
      cat("   ⚠️ Erreur:", e$message, "\n\n")
    })
  }
  
  if (length(resultats) > 0) {
    resultats_df <- do.call(rbind, resultats)
    print(resultats_df)
    cat("\n")
    return(resultats_df)
  }
  
  return(NULL)
}

# =============================================================================
# ANALYSE DES ERREURS DE PRÉVISION
# =============================================================================

analyser_erreurs_prevision <- function(ts_data) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 ANALYSE DES ERREURS DE PRÉVISION\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  train_size <- floor(length(ts_data) * 0.8)
  train_data <- ts_data[1:train_size]
  test_data <- ts_data[(train_size + 1):length(ts_data)]
  
  freq <- frequency(ts_data)
  train_ts <- ts(train_data, frequency = freq)
  
  h <- min(500, length(test_data))
  test_h <- test_data[1:h]
  
  # Ajuster modèles
  modeles <- list()
  
  tryCatch({
    arima <- auto.arima(train_ts, seasonal = TRUE, stepwise = TRUE)
    modeles[["ARIMA"]] <- arima
  }, error = function(e) {
    cat("⚠️ Erreur ARIMA:", e$message, "\n")
  })
  
  erreurs_analyse <- list()
  
  for (nom_modele in names(modeles)) {
    cat("📊 Analyse erreurs", nom_modele, "...\n")
    
    tryCatch({
      prev <- forecast(modeles[[nom_modele]], h = h)
      prev_vals <- as.numeric(prev$mean[1:h])
      
      erreurs <- test_h - prev_vals
      erreurs <- erreurs[!is.na(erreurs) & is.finite(erreurs)]
      
      if (length(erreurs) > 0) {
        # Statistiques des erreurs
        mean_error <- mean(erreurs)
        sd_error <- sd(erreurs)
        skewness <- mean((erreurs - mean_error)^3) / (sd_error^3)
        kurtosis <- mean((erreurs - mean_error)^4) / (sd_error^4)
        
        # Test de normalité (Shapiro-Wilk sur échantillon)
        if (length(erreurs) > 5000) {
          echantillon <- sample(erreurs, 5000)
        } else {
          echantillon <- erreurs
        }
        
        test_norm <- shapiro.test(echantillon)
        
        erreurs_analyse[[nom_modele]] <- data.frame(
          Modele = nom_modele,
          Mean_Error = mean_error,
          SD_Error = sd_error,
          Skewness = skewness,
          Kurtosis = kurtosis,
          Shapiro_pvalue = test_norm$p.value,
          Est_Normal = test_norm$p.value > 0.05
        )
        
        cat("   Erreur moyenne:", round(mean_error, 2), "\n")
        cat("   Écart-type:", round(sd_error, 2), "\n")
        cat("   Skewness:", round(skewness, 3), "\n")
        cat("   Test normalité p-value:", format(test_norm$p.value, scientific = TRUE), "\n\n")
        
        # Graphique distribution des erreurs
        p <- ggplot(data.frame(Erreurs = erreurs), aes(x = Erreurs)) +
          geom_histogram(bins = 50, fill = "steelblue", alpha = 0.7) +
          geom_vline(xintercept = 0, color = "red", linetype = "dashed") +
          labs(title = paste("Distribution des Erreurs -", nom_modele),
               x = "Erreur (Observé - Prédit)", y = "Fréquence") +
          theme_minimal()
        
        png(paste0("figures/erreurs_", nom_modele, ".png"), width = 1000, height = 600)
        print(p)
        dev.off()
        
        cat("   ✅ Graphique sauvegardé: figures/erreurs_", nom_modele, ".png\n\n", sep = "")
      }
    }, error = function(e) {
      cat("   ⚠️ Erreur:", e$message, "\n\n")
    })
  }
  
  if (length(erreurs_analyse) > 0) {
    resultats_df <- do.call(rbind, erreurs_analyse)
    print(resultats_df)
    cat("\n")
    return(resultats_df)
  }
  
  return(NULL)
}

# =============================================================================
# FONCTION PRINCIPALE
# =============================================================================

executer_validation_previsions <- function() {
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  cat("✅ VALIDATION DES PRÉVISIONS\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Charger les données
  df <- charger_dataset()
  
  # Créer série temporelle
  consommation_ts <- ts(df$Consommation, 
                       frequency = 24,
                       start = c(year(min(df$Date)), yday(min(df$Date))))
  
  # Échantillonner si nécessaire
  if (length(consommation_ts) > 50000) {
    indices <- seq(1, length(consommation_ts), by = max(1, floor(length(consommation_ts) / 50000)))
    consommation_ts <- consommation_ts[indices]
  }
  
  # 1. Validation par horizon
  resultats_horizon <- validation_par_horizon(consommation_ts, horizons = c(1, 6, 12, 24, 48, 72))
  
  # 2. Validation intervalles de confiance
  resultats_intervalles <- validation_intervalles_confiance(consommation_ts, niveau = 0.95)
  
  # 3. Analyse des erreurs
  resultats_erreurs <- analyser_erreurs_prevision(consommation_ts)
  
  # Sauvegarder
  if (!dir.exists("data")) {
    dir.create("data", recursive = TRUE)
  }
  
  if (!is.null(resultats_horizon)) {
    write.csv(resultats_horizon, get_path_validations("validation_par_horizon.csv"), row.names = FALSE)
  }
  
  if (!is.null(resultats_intervalles)) {
    write.csv(resultats_intervalles, get_path_validations("validation_intervalles.csv"), row.names = FALSE)
  }
  
  if (!is.null(resultats_erreurs)) {
    write.csv(resultats_erreurs, get_path_analyses("analyse_erreurs.csv"), row.names = FALSE)
  }
  
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("✅ VALIDATION DES PRÉVISIONS TERMINÉE\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  cat("📁 Fichiers créés:\n")
  cat("   - figures/validation_par_horizon.png\n")
  cat("   - figures/erreurs_*.png\n")
  cat("   - data/validation_par_horizon.csv\n")
  cat("   - data/validation_intervalles.csv\n")
  cat("   - data/analyse_erreurs.csv\n\n")
  
  return(list(
    horizon = resultats_horizon,
    intervalles = resultats_intervalles,
    erreurs = resultats_erreurs
  ))
}

# =============================================================================
# EXÉCUTION
# =============================================================================

# Fonction pour exécuter avec sauvegarde des logs
executer_avec_logs <- function() {
  # Créer dossier logs
  if (!dir.exists("logs")) {
    dir.create("logs", recursive = TRUE)
  }
  
  # Nom du fichier de log avec timestamp
  timestamp <- format(Sys.time(), "%Y%m%d_%H%M%S")
  fichier_log <- paste0("logs/validation_previsions_", timestamp, ".log")
  
  # Ouvrir le fichier de log
  sink(fichier_log, split = TRUE)  # split = TRUE pour afficher ET sauvegarder
  
  cat("=", paste0(rep("=", 78), collapse = ""), "=\n", sep = "")
  cat("📝 LOG D'EXÉCUTION - VALIDATION DES PRÉVISIONS\n")
  cat("=", paste0(rep("=", 78), collapse = ""), "=\n", sep = "")
  cat("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
  cat("Script: validation_previsions.R\n\n")
  
  tryCatch({
    resultats <- executer_validation_previsions()
    
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
    sink()  # Fermer le fichier de log
  })
}

# Exécuter automatiquement
projet_dir <- "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION"
if (dir.exists(projet_dir)) {
  setwd(projet_dir)
}

# Exécuter avec logs
resultats <- executer_avec_logs()

