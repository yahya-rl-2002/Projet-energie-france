# =============================================================================
# VALIDATION CROISÉE DES MODÈLES
# =============================================================================
# Validation croisée temporelle (Time Series Cross-Validation) pour évaluer
# la robustesse des modèles sur différentes périodes

library(tidyverse)
library(forecast)
library(tseries)
library(urca)
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
# VALIDATION CROISÉE TEMPORELLE
# =============================================================================

validation_croisee_temporelle <- function(ts_data, n_folds = 5, train_size = 0.8) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("🔄 VALIDATION CROISÉE TEMPORELLE\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  n <- length(ts_data)
  train_length <- floor(n * train_size)
  test_length <- n - train_length
  
  # Calculer taille des folds
  fold_size <- floor(test_length / n_folds)
  
  cat("📊 Configuration:\n")
  cat("   Taille totale:", n, "observations\n")
  cat("   Taille train initial:", train_length, "observations\n")
  cat("   Taille test:", test_length, "observations\n")
  cat("   Nombre de folds:", n_folds, "\n")
  cat("   Taille par fold:", fold_size, "observations\n\n")
  
  resultats <- list()
  
  for (fold in 1:n_folds) {
    cat("📊 Fold", fold, "/", n_folds, "...\n")
    
    # Définir train et test pour ce fold
    train_end <- train_length + (fold - 1) * fold_size
    test_start <- train_end + 1
    test_end <- min(train_length + fold * fold_size, n)
    
    if (test_end <= test_start) {
      cat("   ⚠️ Fold trop petit, ignoré\n\n")
      next
    }
    
    train_data <- ts_data[1:train_end]
    test_data <- ts_data[test_start:test_end]
    
    cat("   Train: observations 1 à", train_end, "\n")
    cat("   Test: observations", test_start, "à", test_end, "\n")
    
    # Créer série temporelle
    freq <- frequency(ts_data)
    train_ts <- ts(train_data, frequency = freq)
    
    # Ajuster modèles
    modeles_fits <- list()
    
    # 1. ARIMA auto
    tryCatch({
      arima_auto <- auto.arima(train_ts, seasonal = TRUE, stepwise = FALSE, approximation = FALSE)
      modeles_fits[["ARIMA_auto"]] <- arima_auto
    }, error = function(e) {
      cat("   ⚠️ Erreur ARIMA auto:", e$message, "\n")
    })
    
    # 2. SARIMA
    tryCatch({
      sarima <- auto.arima(train_ts, seasonal = TRUE, stepwise = TRUE)
      modeles_fits[["SARIMA"]] <- sarima
    }, error = function(e) {
      cat("   ⚠️ Erreur SARIMA:", e$message, "\n")
    })
    
    # 3. ETS
    tryCatch({
      ets_model <- ets(train_ts)
      modeles_fits[["ETS"]] <- ets_model
    }, error = function(e) {
      cat("   ⚠️ Erreur ETS:", e$message, "\n")
    })
    
    # Prévoir sur le test
    metrics_fold <- list()
    
    for (nom_modele in names(modeles_fits)) {
      modele <- modeles_fits[[nom_modele]]
      
      tryCatch({
        if (nom_modele == "ETS") {
          prev <- forecast(modele, h = length(test_data))
        } else {
          prev <- forecast(modele, h = length(test_data))
        }
        
        prev_values <- as.numeric(prev$mean[1:length(test_data)])
        
        # Calculer métriques
        rmse <- sqrt(mean((test_data - prev_values)^2, na.rm = TRUE))
        mae <- mean(abs(test_data - prev_values), na.rm = TRUE)
        mape <- mean(abs((test_data - prev_values) / test_data) * 100, na.rm = TRUE)
        
        metrics_fold[[nom_modele]] <- list(
          RMSE = rmse,
          MAE = mae,
          MAPE = mape,
          Fold = fold
        )
        
        cat("   ✅", nom_modele, "- RMSE:", round(rmse, 2), "\n")
      }, error = function(e) {
        cat("   ⚠️ Erreur prévision", nom_modele, ":", e$message, "\n")
      })
    }
    
    resultats[[fold]] <- metrics_fold
    cat("\n")
  }
  
  # Agréger résultats
  cat("📊 Agrégation des résultats...\n\n")
  
  resultats_agreges <- list()
  
  for (nom_modele in unique(unlist(lapply(resultats, names)))) {
    metrics_all_folds <- lapply(resultats, function(x) x[[nom_modele]])
    metrics_all_folds <- metrics_all_folds[!sapply(metrics_all_folds, is.null)]
    
    if (length(metrics_all_folds) > 0) {
      rmse_vals <- sapply(metrics_all_folds, function(x) x$RMSE)
      mae_vals <- sapply(metrics_all_folds, function(x) x$MAE)
      mape_vals <- sapply(metrics_all_folds, function(x) x$MAPE)
      
      resultats_agreges[[nom_modele]] <- data.frame(
        Modele = nom_modele,
        RMSE_moyen = mean(rmse_vals, na.rm = TRUE),
        RMSE_sd = sd(rmse_vals, na.rm = TRUE),
        MAE_moyen = mean(mae_vals, na.rm = TRUE),
        MAE_sd = sd(mae_vals, na.rm = TRUE),
        MAPE_moyen = mean(mape_vals, na.rm = TRUE),
        MAPE_sd = sd(mape_vals, na.rm = TRUE),
        N_folds = length(metrics_all_folds)
      )
    }
  }
  
  if (length(resultats_agreges) > 0) {
    resultats_df <- do.call(rbind, resultats_agreges) %>%
      arrange(RMSE_moyen)
    
    print(resultats_df)
    cat("\n")
    
    return(list(
      resultats_par_fold = resultats,
      resultats_agreges = resultats_df
    ))
  } else {
    cat("⚠️ Aucun résultat valide\n\n")
    return(NULL)
  }
}

# =============================================================================
# VALIDATION CROISÉE PAR BLOCS
# =============================================================================

validation_croisee_par_blocs <- function(ts_data, n_blocks = 5) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📦 VALIDATION CROISÉE PAR BLOCS\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  n <- length(ts_data)
  block_size <- floor(n / n_blocks)
  
  cat("📊 Configuration:\n")
  cat("   Taille totale:", n, "observations\n")
  cat("   Nombre de blocs:", n_blocks, "\n")
  cat("   Taille par bloc:", block_size, "observations\n\n")
  
  resultats <- list()
  
  for (block in 1:n_blocks) {
    cat("📦 Bloc", block, "/", n_blocks, "...\n")
    
    # Définir train et test
    test_start <- (block - 1) * block_size + 1
    test_end <- min(block * block_size, n)
    
    train_indices <- c(1:(test_start - 1), (test_end + 1):n)
    train_indices <- train_indices[train_indices > 0 & train_indices <= n]
    
    if (length(train_indices) < 100 || length(test_start:test_end) < 10) {
      cat("   ⚠️ Bloc trop petit, ignoré\n\n")
      next
    }
    
    train_data <- ts_data[train_indices]
    test_data <- ts_data[test_start:test_end]
    
    cat("   Train:", length(train_data), "observations\n")
    cat("   Test:", length(test_data), "observations\n")
    
    # Créer série temporelle
    freq <- frequency(ts_data)
    train_ts <- ts(train_data, frequency = freq)
    
    # Ajuster modèles
    modeles_fits <- list()
    
    tryCatch({
      arima_auto <- auto.arima(train_ts, seasonal = TRUE, stepwise = TRUE)
      modeles_fits[["ARIMA_auto"]] <- arima_auto
    }, error = function(e) {
      cat("   ⚠️ Erreur ARIMA:", e$message, "\n")
    })
    
    tryCatch({
      ets_model <- ets(train_ts)
      modeles_fits[["ETS"]] <- ets_model
    }, error = function(e) {
      cat("   ⚠️ Erreur ETS:", e$message, "\n")
    })
    
    # Prévoir et évaluer
    metrics_block <- list()
    
    for (nom_modele in names(modeles_fits)) {
      modele <- modeles_fits[[nom_modele]]
      
      tryCatch({
        prev <- forecast(modele, h = length(test_data))
        prev_values <- as.numeric(prev$mean[1:length(test_data)])
        
        rmse <- sqrt(mean((test_data - prev_values)^2, na.rm = TRUE))
        mae <- mean(abs(test_data - prev_values), na.rm = TRUE)
        mape <- mean(abs((test_data - prev_values) / test_data) * 100, na.rm = TRUE)
        
        metrics_block[[nom_modele]] <- list(
          RMSE = rmse,
          MAE = mae,
          MAPE = mape,
          Block = block
        )
        
        cat("   ✅", nom_modele, "- RMSE:", round(rmse, 2), "\n")
      }, error = function(e) {
        cat("   ⚠️ Erreur prévision:", e$message, "\n")
      })
    }
    
    resultats[[block]] <- metrics_block
    cat("\n")
  }
  
  # Agréger
  resultats_agreges <- list()
  
  for (nom_modele in unique(unlist(lapply(resultats, names)))) {
    metrics_all_blocks <- lapply(resultats, function(x) x[[nom_modele]])
    metrics_all_blocks <- metrics_all_blocks[!sapply(metrics_all_blocks, is.null)]
    
    if (length(metrics_all_blocks) > 0) {
      rmse_vals <- sapply(metrics_all_blocks, function(x) x$RMSE)
      mae_vals <- sapply(metrics_all_blocks, function(x) x$MAE)
      mape_vals <- sapply(metrics_all_blocks, function(x) x$MAPE)
      
      resultats_agreges[[nom_modele]] <- data.frame(
        Modele = nom_modele,
        RMSE_moyen = mean(rmse_vals, na.rm = TRUE),
        RMSE_sd = sd(rmse_vals, na.rm = TRUE),
        MAE_moyen = mean(mae_vals, na.rm = TRUE),
        MAE_sd = sd(mae_vals, na.rm = TRUE),
        MAPE_moyen = mean(mape_vals, na.rm = TRUE),
        MAPE_sd = sd(mape_vals, na.rm = TRUE),
        N_blocks = length(metrics_all_blocks)
      )
    }
  }
  
  if (length(resultats_agreges) > 0) {
    resultats_df <- do.call(rbind, resultats_agreges) %>%
      arrange(RMSE_moyen)
    
    print(resultats_df)
    cat("\n")
    
    return(list(
      resultats_par_block = resultats,
      resultats_agreges = resultats_df
    ))
  }
  
  return(NULL)
}

# =============================================================================
# VISUALISATION DES RÉSULTATS
# =============================================================================

visualiser_validation_croisee <- function(resultats_temporelle, resultats_blocs) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 VISUALISATION DES RÉSULTATS\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  plots <- list()
  
  # Graphique validation temporelle
  if (!is.null(resultats_temporelle) && !is.null(resultats_temporelle$resultats_agreges)) {
    p1 <- resultats_temporelle$resultats_agreges %>%
      ggplot(aes(x = Modele, y = RMSE_moyen, fill = Modele)) +
      geom_bar(stat = "identity") +
      geom_errorbar(aes(ymin = RMSE_moyen - RMSE_sd, 
                       ymax = RMSE_moyen + RMSE_sd),
                   width = 0.2) +
      labs(title = "Validation Croisée Temporelle - RMSE",
           x = "Modèle", y = "RMSE (moyenne ± écart-type)") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
      scale_fill_brewer(palette = "Set2")
    
    plots[["temporelle"]] <- p1
  }
  
  # Graphique validation par blocs
  if (!is.null(resultats_blocs) && !is.null(resultats_blocs$resultats_agreges)) {
    p2 <- resultats_blocs$resultats_agreges %>%
      ggplot(aes(x = Modele, y = RMSE_moyen, fill = Modele)) +
      geom_bar(stat = "identity") +
      geom_errorbar(aes(ymin = RMSE_moyen - RMSE_sd, 
                       ymax = RMSE_moyen + RMSE_sd),
                   width = 0.2) +
      labs(title = "Validation Croisée par Blocs - RMSE",
           x = "Modèle", y = "RMSE (moyenne ± écart-type)") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
      scale_fill_brewer(palette = "Set3")
    
    plots[["blocs"]] <- p2
  }
  
  # Sauvegarder
  if (length(plots) > 0) {
    png("figures/validation_croisee.png", width = 1400, height = 600)
    do.call(grid.arrange, c(plots, ncol = length(plots)))
    dev.off()
    
    cat("✅ Graphiques sauvegardés: figures/validation_croisee.png\n\n")
  }
}

# =============================================================================
# FONCTION PRINCIPALE
# =============================================================================

executer_validation_croisee <- function() {
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  cat("🔄 VALIDATION CROISÉE DES MODÈLES\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Charger les données
  df <- charger_dataset()
  
  # Créer série temporelle
  consommation_ts <- ts(df$Consommation, 
                       frequency = 24,  # Données horaires
                       start = c(year(min(df$Date)), 
                                yday(min(df$Date))))
  
  cat("📊 Série temporelle créée:\n")
  cat("   Observations:", length(consommation_ts), "\n")
  cat("   Fréquence:", frequency(consommation_ts), "h\n\n")
  
  # Échantillonner si trop de données
  if (length(consommation_ts) > 50000) {
    cat("📊 Échantillonnage pour performance...\n")
    indices <- seq(1, length(consommation_ts), by = max(1, floor(length(consommation_ts) / 50000)))
    consommation_ts <- consommation_ts[indices]
    cat("   Taille après échantillonnage:", length(consommation_ts), "\n\n")
  }
  
  # 1. Validation croisée temporelle
  resultats_temporelle <- validation_croisee_temporelle(consommation_ts, n_folds = 5)
  
  # 2. Validation croisée par blocs
  resultats_blocs <- validation_croisee_par_blocs(consommation_ts, n_blocks = 5)
  
  # 3. Visualisations
  visualiser_validation_croisee(resultats_temporelle, resultats_blocs)
  
  # Sauvegarder résultats
  if (!dir.exists("data")) {
    dir.create("data", recursive = TRUE)
  }
  
  if (!is.null(resultats_temporelle) && !is.null(resultats_temporelle$resultats_agreges)) {
    write.csv(resultats_temporelle$resultats_agreges, 
              get_path_validations("validation_croisee_temporelle.csv"), 
              row.names = FALSE)
  }
  
  if (!is.null(resultats_blocs) && !is.null(resultats_blocs$resultats_agreges)) {
    write.csv(resultats_blocs$resultats_agreges, 
              get_path_validations("validation_croisee_blocs.csv"), 
              row.names = FALSE)
  }
  
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("✅ VALIDATION CROISÉE TERMINÉE\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  cat("📁 Fichiers créés:\n")
  cat("   - figures/validation_croisee.png\n")
  cat("   - data/validation_croisee_temporelle.csv\n")
  cat("   - data/validation_croisee_blocs.csv\n\n")
  
  return(list(
    temporelle = resultats_temporelle,
    blocs = resultats_blocs
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
  fichier_log <- paste0("logs/validation_croisee_", timestamp, ".log")
  
  # Ouvrir le fichier de log
  sink(fichier_log, split = TRUE)  # split = TRUE pour afficher ET sauvegarder
  
  cat("=", paste0(rep("=", 78), collapse = ""), "=\n", sep = "")
  cat("📝 LOG D'EXÉCUTION - VALIDATION CROISÉE\n")
  cat("=", paste0(rep("=", 78), collapse = ""), "=\n", sep = "")
  cat("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
  cat("Script: validation_croisee.R\n\n")
  
  tryCatch({
    resultats <- executer_validation_croisee()
    
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

