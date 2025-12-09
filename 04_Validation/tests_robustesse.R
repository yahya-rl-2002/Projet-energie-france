# =============================================================================
# TESTS DE ROBUSTESSE
# =============================================================================
# Tests de robustesse des modèles face aux variations de données

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
# TEST DE ROBUSTESSE AUX OUTLIERS
# =============================================================================

test_robustesse_outliers <- function(ts_data, n_outliers = 10, outlier_factor = 2) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("🔍 TEST DE ROBUSTESSE AUX OUTLIERS\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Créer copie avec outliers
  ts_avec_outliers <- ts_data
  n <- length(ts_data)
  
  # Ajouter outliers aléatoires
  set.seed(42)
  outlier_indices <- sample(1:n, min(n_outliers, n))
  
  for (idx in outlier_indices) {
    # Ajouter ou soustraire selon le signe
    signe <- sample(c(-1, 1), 1)
    ts_avec_outliers[idx] <- ts_data[idx] + signe * outlier_factor * sd(ts_data, na.rm = TRUE)
  }
  
  cat("📊 Outliers ajoutés:", length(outlier_indices), "\n")
  cat("   Facteur:", outlier_factor, "× écart-type\n\n")
  
  # Diviser train/test
  train_size <- floor(length(ts_data) * 0.8)
  train_original <- ts_data[1:train_size]
  train_outliers <- ts_avec_outliers[1:train_size]
  test_data <- ts_data[(train_size + 1):length(ts_data)]
  
  freq <- frequency(ts_data)
  train_ts_original <- ts(train_original, frequency = freq)
  train_ts_outliers <- ts(train_outliers, frequency = freq)
  
  # Ajuster modèles sur données originales
  cat("📊 Ajustement sur données originales...\n")
  modeles_original <- list()
  
  tryCatch({
    arima_orig <- auto.arima(train_ts_original, seasonal = TRUE, stepwise = TRUE)
    modeles_original[["ARIMA"]] <- arima_orig
  }, error = function(e) {
    cat("   ⚠️ Erreur ARIMA:", e$message, "\n")
  })
  
  tryCatch({
    ets_orig <- ets(train_ts_original)
    modeles_original[["ETS"]] <- ets_orig
  }, error = function(e) {
    cat("   ⚠️ Erreur ETS:", e$message, "\n")
  })
  
  # Ajuster modèles sur données avec outliers
  cat("📊 Ajustement sur données avec outliers...\n")
  modeles_outliers <- list()
  
  tryCatch({
    arima_out <- auto.arima(train_ts_outliers, seasonal = TRUE, stepwise = TRUE)
    modeles_outliers[["ARIMA"]] <- arima_out
  }, error = function(e) {
    cat("   ⚠️ Erreur ARIMA:", e$message, "\n")
  })
  
  tryCatch({
    ets_out <- ets(train_ts_outliers)
    modeles_outliers[["ETS"]] <- ets_out
  }, error = function(e) {
    cat("   ⚠️ Erreur ETS:", e$message, "\n")
  })
  
  # Comparer prévisions
  resultats <- list()
  
  for (nom_modele in names(modeles_original)) {
    if (nom_modele %in% names(modeles_outliers)) {
      cat("📊 Comparaison", nom_modele, "...\n")
      
      tryCatch({
        # Prévisions avec modèle original
        prev_orig <- forecast(modeles_original[[nom_modele]], h = length(test_data))
        prev_orig_vals <- as.numeric(prev_orig$mean[1:length(test_data)])
        
        # Prévisions avec modèle outliers
        prev_out <- forecast(modeles_outliers[[nom_modele]], h = length(test_data))
        prev_out_vals <- as.numeric(prev_out$mean[1:length(test_data)])
        
        # Métriques
        rmse_orig <- sqrt(mean((test_data - prev_orig_vals)^2, na.rm = TRUE))
        rmse_out <- sqrt(mean((test_data - prev_out_vals)^2, na.rm = TRUE))
        
        mae_orig <- mean(abs(test_data - prev_orig_vals), na.rm = TRUE)
        mae_out <- mean(abs(test_data - prev_out_vals), na.rm = TRUE)
        
        degradation <- ((rmse_out - rmse_orig) / rmse_orig) * 100
        
        resultats[[nom_modele]] <- data.frame(
          Modele = nom_modele,
          RMSE_original = rmse_orig,
          RMSE_outliers = rmse_out,
          MAE_original = mae_orig,
          MAE_outliers = mae_out,
          Degradation_pct = degradation
        )
        
        cat("   RMSE original:", round(rmse_orig, 2), "\n")
        cat("   RMSE avec outliers:", round(rmse_out, 2), "\n")
        cat("   Dégradation:", round(degradation, 2), "%\n\n")
      }, error = function(e) {
        cat("   ⚠️ Erreur:", e$message, "\n\n")
      })
    }
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
# TEST DE ROBUSTESSE AUX DONNÉES MANQUANTES
# =============================================================================

test_robustesse_manquantes <- function(ts_data, pct_manquantes = 0.1) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("🔍 TEST DE ROBUSTESSE AUX DONNÉES MANQUANTES\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Créer copie avec données manquantes
  ts_manquantes <- ts_data
  n <- length(ts_data)
  n_manquantes <- floor(n * pct_manquantes)
  
  set.seed(42)
  indices_manquantes <- sample(1:n, n_manquantes)
  ts_manquantes[indices_manquantes] <- NA
  
  cat("📊 Données manquantes:", n_manquantes, "(", pct_manquantes * 100, "%)\n\n")
  
  # Interpoler les valeurs manquantes
  ts_interpole <- na.interp(ts_manquantes)
  
  # Diviser train/test
  train_size <- floor(length(ts_data) * 0.8)
  train_original <- ts_data[1:train_size]
  train_interpole <- ts_interpole[1:train_size]
  test_data <- ts_data[(train_size + 1):length(ts_data)]
  
  freq <- frequency(ts_data)
  train_ts_original <- ts(train_original, frequency = freq)
  train_ts_interpole <- ts(train_interpole, frequency = freq)
  
  # Ajuster modèles
  cat("📊 Ajustement sur données originales...\n")
  modeles_original <- list()
  
  tryCatch({
    arima_orig <- auto.arima(train_ts_original, seasonal = TRUE, stepwise = TRUE)
    modeles_original[["ARIMA"]] <- arima_orig
  }, error = function(e) {
    cat("   ⚠️ Erreur ARIMA:", e$message, "\n")
  })
  
  cat("📊 Ajustement sur données interpolées...\n")
  modeles_interpole <- list()
  
  tryCatch({
    arima_int <- auto.arima(train_ts_interpole, seasonal = TRUE, stepwise = TRUE)
    modeles_interpole[["ARIMA"]] <- arima_int
  }, error = function(e) {
    cat("   ⚠️ Erreur ARIMA:", e$message, "\n")
  })
  
  # Comparer
  resultats <- list()
  
  for (nom_modele in names(modeles_original)) {
    if (nom_modele %in% names(modeles_interpole)) {
      cat("📊 Comparaison", nom_modele, "...\n")
      
      tryCatch({
        prev_orig <- forecast(modeles_original[[nom_modele]], h = length(test_data))
        prev_orig_vals <- as.numeric(prev_orig$mean[1:length(test_data)])
        
        prev_int <- forecast(modeles_interpole[[nom_modele]], h = length(test_data))
        prev_int_vals <- as.numeric(prev_int$mean[1:length(test_data)])
        
        rmse_orig <- sqrt(mean((test_data - prev_orig_vals)^2, na.rm = TRUE))
        rmse_int <- sqrt(mean((test_data - prev_int_vals)^2, na.rm = TRUE))
        
        degradation <- ((rmse_int - rmse_orig) / rmse_orig) * 100
        
        resultats[[nom_modele]] <- data.frame(
          Modele = nom_modele,
          RMSE_original = rmse_orig,
          RMSE_interpole = rmse_int,
          Degradation_pct = degradation
        )
        
        cat("   RMSE original:", round(rmse_orig, 2), "\n")
        cat("   RMSE interpolé:", round(rmse_int, 2), "\n")
        cat("   Dégradation:", round(degradation, 2), "%\n\n")
      }, error = function(e) {
        cat("   ⚠️ Erreur:", e$message, "\n\n")
      })
    }
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
# TEST DE ROBUSTESSE À LA TAILLE D'ÉCHANTILLON
# =============================================================================

test_robustesse_taille <- function(ts_data, tailles = c(0.3, 0.5, 0.7, 0.9)) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📏 TEST DE ROBUSTESSE À LA TAILLE D'ÉCHANTILLON\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  n <- length(ts_data)
  test_size <- floor(n * 0.2)
  test_data <- ts_data[(n - test_size + 1):n]
  
  resultats <- list()
  
  for (taille_pct in tailles) {
    train_size <- floor(n * taille_pct)
    
    if (train_size < 100) {
      cat("⚠️ Taille trop petite:", train_size, ", ignorée\n\n")
      next
    }
    
    cat("📊 Taille train:", train_size, "(", taille_pct * 100, "%)\n")
    
    train_data <- ts_data[1:train_size]
    freq <- frequency(ts_data)
    train_ts <- ts(train_data, frequency = freq)
    
    # Ajuster modèles
    modeles <- list()
    
    tryCatch({
      arima <- auto.arima(train_ts, seasonal = TRUE, stepwise = TRUE)
      modeles[["ARIMA"]] <- arima
    }, error = function(e) {
      cat("   ⚠️ Erreur ARIMA:", e$message, "\n")
    })
    
    # Prévoir et évaluer
    for (nom_modele in names(modeles)) {
      tryCatch({
        prev <- forecast(modeles[[nom_modele]], h = length(test_data))
        prev_vals <- as.numeric(prev$mean[1:length(test_data)])
        
        rmse <- sqrt(mean((test_data - prev_vals)^2, na.rm = TRUE))
        mae <- mean(abs(test_data - prev_vals), na.rm = TRUE)
        
        resultats[[paste0(nom_modele, "_", taille_pct)]] <- data.frame(
          Modele = nom_modele,
          Taille_train = train_size,
          Taille_pct = taille_pct,
          RMSE = rmse,
          MAE = mae
        )
        
        cat("   ✅", nom_modele, "- RMSE:", round(rmse, 2), "\n")
      }, error = function(e) {
        cat("   ⚠️ Erreur prévision:", e$message, "\n")
      })
    }
    
    cat("\n")
  }
  
  if (length(resultats) > 0) {
    resultats_df <- do.call(rbind, resultats)
    
    # Graphique
    p <- resultats_df %>%
      ggplot(aes(x = Taille_pct, y = RMSE, color = Modele)) +
      geom_line(size = 1.2) +
      geom_point(size = 2) +
      labs(title = "Robustesse à la Taille d'Échantillon",
           x = "Proportion de données d'entraînement",
           y = "RMSE") +
      theme_minimal() +
      scale_x_continuous(labels = scales::percent)
    
    png("figures/robustesse_taille.png", width = 1000, height = 600)
    print(p)
    dev.off()
    
    cat("✅ Graphique sauvegardé: figures/robustesse_taille.png\n\n")
    
    print(resultats_df)
    cat("\n")
    
    return(resultats_df)
  }
  
  return(NULL)
}

# =============================================================================
# FONCTION PRINCIPALE
# =============================================================================

executer_tests_robustesse <- function() {
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  cat("🛡️ TESTS DE ROBUSTESSE\n")
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
  
  # 1. Test aux outliers
  resultats_outliers <- test_robustesse_outliers(consommation_ts, n_outliers = 20)
  
  # 2. Test aux données manquantes
  resultats_manquantes <- test_robustesse_manquantes(consommation_ts, pct_manquantes = 0.1)
  
  # 3. Test à la taille
  resultats_taille <- test_robustesse_taille(consommation_ts)
  
  # Sauvegarder
  if (!dir.exists("data")) {
    dir.create("data", recursive = TRUE)
  }
  
  if (!is.null(resultats_outliers)) {
    write.csv(resultats_outliers, get_path_validations("robustesse_outliers.csv"), row.names = FALSE)
  }
  
  if (!is.null(resultats_manquantes)) {
    write.csv(resultats_manquantes, get_path_validations("robustesse_manquantes.csv"), row.names = FALSE)
  }
  
  if (!is.null(resultats_taille)) {
    write.csv(resultats_taille, get_path_validations("robustesse_taille.csv"), row.names = FALSE)
  }
  
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("✅ TESTS DE ROBUSTESSE TERMINÉS\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  cat("📁 Fichiers créés:\n")
  cat("   - figures/robustesse_taille.png\n")
  cat("   - data/robustesse_outliers.csv\n")
  cat("   - data/robustesse_manquantes.csv\n")
  cat("   - data/robustesse_taille.csv\n\n")
  
  return(list(
    outliers = resultats_outliers,
    manquantes = resultats_manquantes,
    taille = resultats_taille
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
  fichier_log <- paste0("logs/tests_robustesse_", timestamp, ".log")
  
  # Ouvrir le fichier de log
  sink(fichier_log, split = TRUE)  # split = TRUE pour afficher ET sauvegarder
  
  cat("=", paste0(rep("=", 78), collapse = ""), "=\n", sep = "")
  cat("📝 LOG D'EXÉCUTION - TESTS DE ROBUSTESSE\n")
  cat("=", paste0(rep("=", 78), collapse = ""), "=\n", sep = "")
  cat("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
  cat("Script: tests_robustesse.R\n\n")
  
  tryCatch({
    resultats <- executer_tests_robustesse()
    
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

