# =============================================================================
# COMPARAISON AVANCÉE DES MODÈLES
# =============================================================================
# Comparaison approfondie de tous les modèles avec métriques complètes

library(tidyverse)
library(forecast)
library(tseries)
library(ggplot2)
library(gridExtra)
library(knitr)

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
# AJUSTER TOUS LES MODÈLES
# =============================================================================

ajuster_tous_modeles <- function(train_ts) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("🔧 AJUSTEMENT DE TOUS LES MODÈLES\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  modeles <- list()
  
  # 1. ARIMA auto
  cat("📊 Ajustement ARIMA auto...\n")
  tryCatch({
    arima_auto <- auto.arima(train_ts, seasonal = TRUE, stepwise = TRUE, approximation = FALSE)
    modeles[["ARIMA_auto"]] <- arima_auto
    cat("   ✅ ARIMA(", paste(arima_auto$arma[c(1, 2, 3, 6, 7)], collapse = ","), ")\n")
  }, error = function(e) {
    cat("   ⚠️ Erreur:", e$message, "\n")
  })
  
  # 2. ETS
  cat("📊 Ajustement ETS...\n")
  tryCatch({
    ets_model <- ets(train_ts)
    modeles[["ETS"]] <- ets_model
    cat("   ✅ ETS(", ets_model$method, ")\n")
  }, error = function(e) {
    cat("   ⚠️ Erreur:", e$message, "\n")
  })
  
  # 3. TBATS
  cat("📊 Ajustement TBATS...\n")
  tryCatch({
    tbats_model <- tbats(train_ts)
    modeles[["TBATS"]] <- tbats_model
    cat("   ✅ TBATS ajusté\n")
  }, error = function(e) {
    cat("   ⚠️ Erreur:", e$message, "\n")
  })
  
  # 4. STL + ARIMA
  cat("📊 Ajustement STL + ARIMA...\n")
  tryCatch({
    stl_decomp <- stl(train_ts, s.window = "periodic")
    stl_arima <- auto.arima(stl_decomp$time.series[, "remainder"], stepwise = TRUE)
    modeles[["STL_ARIMA"]] <- list(stl = stl_decomp, arima = stl_arima)
    cat("   ✅ STL + ARIMA ajusté\n")
  }, error = function(e) {
    cat("   ⚠️ Erreur:", e$message, "\n")
  })
  
  # 5. Naive
  cat("📊 Modèle Naive...\n")
  tryCatch({
    naive_model <- naive(train_ts, h = 1)
    modeles[["Naive"]] <- naive_model
    cat("   ✅ Naive ajusté\n")
  }, error = function(e) {
    cat("   ⚠️ Erreur:", e$message, "\n")
  })
  
  # 6. Seasonal Naive
  cat("📊 Modèle Seasonal Naive...\n")
  tryCatch({
    snaive_model <- snaive(train_ts, h = 1)
    modeles[["Seasonal_Naive"]] <- snaive_model
    cat("   ✅ Seasonal Naive ajusté\n")
  }, error = function(e) {
    cat("   ⚠️ Erreur:", e$message, "\n")
  })
  
  cat("\n✅", length(modeles), "modèles ajustés\n\n")
  
  return(modeles)
}

# =============================================================================
# CALCULER TOUTES LES MÉTRIQUES
# =============================================================================

calculer_toutes_metriques <- function(observations, predictions, modele_obj = NULL) {
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
  
  # AIC, BIC si disponible
  aic <- NA
  bic <- NA
  
  if (!is.null(modele_obj)) {
    if (inherits(modele_obj, "Arima")) {
      aic <- modele_obj$aic
      bic <- BIC(modele_obj)
    } else if (inherits(modele_obj, "ets")) {
      aic <- modele_obj$aic
      bic <- modele_obj$bic
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
    AIC = aic,
    BIC = bic
  ))
}

# =============================================================================
# COMPARAISON COMPLÈTE
# =============================================================================

comparer_tous_modeles <- function(ts_data) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 COMPARAISON COMPLÈTE DES MODÈLES\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Diviser train/test
  train_size <- floor(length(ts_data) * 0.8)
  train_data <- ts_data[1:train_size]
  test_data <- ts_data[(train_size + 1):length(ts_data)]
  
  freq <- frequency(ts_data)
  train_ts <- ts(train_data, frequency = freq)
  
  cat("📊 Train:", length(train_data), "observations\n")
  cat("📊 Test:", length(test_data), "observations\n\n")
  
  # Ajuster tous les modèles
  modeles <- ajuster_tous_modeles(train_ts)
  
  if (length(modeles) == 0) {
    cat("⚠️ Aucun modèle ajusté\n\n")
    return(NULL)
  }
  
  # Prévoir et évaluer
  h <- min(500, length(test_data))
  test_h <- test_data[1:h]
  
  resultats <- list()
  
  for (nom_modele in names(modeles)) {
    cat("📊 Évaluation", nom_modele, "...\n")
    
    modele <- modeles[[nom_modele]]
    
    tryCatch({
      # Prévision selon le type de modèle
      if (nom_modele == "STL_ARIMA") {
        # Prévision STL + ARIMA
        stl_future <- forecast(modele$stl, h = h)
        arima_future <- forecast(modele$arima, h = h)
        prev_mean <- stl_future$mean + arima_future$mean
      } else {
        prev <- forecast(modele, h = h)
        prev_mean <- as.numeric(prev$mean[1:h])
      }
      
      # Calculer métriques
      metrics <- calculer_toutes_metriques(test_h, prev_mean, modele)
      
      if (!is.null(metrics)) {
        resultats[[nom_modele]] <- data.frame(
          Modele = nom_modele,
          RMSE = metrics$RMSE,
          MAE = metrics$MAE,
          MAPE = metrics$MAPE,
          MSE = metrics$MSE,
          R_squared = metrics$R_squared,
          MASE = metrics$MASE,
          sMAPE = metrics$sMAPE,
          AIC = metrics$AIC,
          BIC = metrics$BIC
        )
        
        cat("   ✅ RMSE:", round(metrics$RMSE, 2), 
            "- MAPE:", round(metrics$MAPE, 2), "%\n")
      }
    }, error = function(e) {
      cat("   ⚠️ Erreur:", e$message, "\n")
    })
    
    cat("\n")
  }
  
  if (length(resultats) > 0) {
    resultats_df <- do.call(rbind, resultats) %>%
      arrange(RMSE)
    
    cat("📊 RÉSULTATS DE LA COMPARAISON:\n\n")
    print(resultats_df)
    cat("\n")
    
    # Graphiques de comparaison
    visualiser_comparaison(resultats_df)
    
    return(list(
      modeles = modeles,
      resultats = resultats_df
    ))
  }
  
  return(NULL)
}

# =============================================================================
# VISUALISATION DE LA COMPARAISON
# =============================================================================

visualiser_comparaison <- function(resultats_df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 CRÉATION DES GRAPHIQUES DE COMPARAISON\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Graphique RMSE
  p1 <- resultats_df %>%
    ggplot(aes(x = reorder(Modele, RMSE), y = RMSE, fill = Modele)) +
    geom_bar(stat = "identity") +
    labs(title = "Comparaison des Modèles - RMSE",
         x = "Modèle", y = "RMSE") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    scale_fill_brewer(palette = "Set2")
  
  # Graphique MAPE
  p2 <- resultats_df %>%
    ggplot(aes(x = reorder(Modele, MAPE), y = MAPE, fill = Modele)) +
    geom_bar(stat = "identity") +
    labs(title = "Comparaison des Modèles - MAPE",
         x = "Modèle", y = "MAPE (%)") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    scale_fill_brewer(palette = "Set3")
  
  # Graphique R²
  if (all(!is.na(resultats_df$R_squared))) {
    p3 <- resultats_df %>%
      ggplot(aes(x = reorder(Modele, R_squared), y = R_squared, fill = Modele)) +
      geom_bar(stat = "identity") +
      labs(title = "Comparaison des Modèles - R²",
           x = "Modèle", y = "R²") +
      theme_minimal() +
      theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
      scale_fill_brewer(palette = "Set1")
    
    png("figures/comparaison_modeles_complete.png", width = 1600, height = 1800)
    grid.arrange(p1, p2, p3, ncol = 1)
    dev.off()
  } else {
    png("figures/comparaison_modeles_complete.png", width = 1400, height = 1200)
    grid.arrange(p1, p2, ncol = 1)
    dev.off()
  }
  
  cat("✅ Graphiques sauvegardés: figures/comparaison_modeles_complete.png\n\n")
  
  # Graphique radar (si possible)
  tryCatch({
    if (require("fmsb", quietly = TRUE)) {
      # Normaliser les métriques pour le radar
      resultats_norm <- resultats_df %>%
        mutate(
          RMSE_norm = 1 - (RMSE - min(RMSE)) / (max(RMSE) - min(RMSE)),
          MAPE_norm = 1 - (MAPE - min(MAPE)) / (max(MAPE) - min(MAPE)),
          R2_norm = R_squared
        ) %>%
        select(Modele, RMSE_norm, MAPE_norm, R2_norm)
      
      # Graphique simple de comparaison multi-métriques
      resultats_long <- resultats_df %>%
        select(Modele, RMSE, MAPE, R_squared) %>%
        pivot_longer(-Modele, names_to = "Metrique", values_to = "Valeur") %>%
        mutate(
          Metrique = case_when(
            Metrique == "RMSE" ~ "RMSE (inversé)",
            Metrique == "MAPE" ~ "MAPE (inversé)",
            Metrique == "R_squared" ~ "R²",
            TRUE ~ Metrique
          ),
          Valeur_norm = ifelse(Metrique %in% c("RMSE (inversé)", "MAPE (inversé)"),
                              1 - (Valeur - min(Valeur)) / (max(Valeur) - min(Valeur)),
                              Valeur)
        )
      
      p_radar <- resultats_long %>%
        ggplot(aes(x = Metrique, y = Valeur_norm, fill = Modele)) +
        geom_bar(stat = "identity", position = "dodge") +
        labs(title = "Comparaison Multi-Métriques (Normalisées)",
             x = "Métrique", y = "Valeur Normalisée") +
        theme_minimal() +
        theme(axis.text.x = element_text(angle = 45, hjust = 1))
      
      png("figures/comparaison_multimetriques.png", width = 1200, height = 600)
      print(p_radar)
      dev.off()
      
      cat("✅ Graphique multi-métriques sauvegardé: figures/comparaison_multimetriques.png\n\n")
    }
  }, error = function(e) {
    cat("⚠️ Graphique radar non créé:", e$message, "\n\n")
  })
}

# =============================================================================
# TABLEAU RÉCAPITULATIF
# =============================================================================

creer_tableau_recapitulatif <- function(resultats_df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📋 TABLEAU RÉCAPITULATIF\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Classer par RMSE
  classement_rmse <- resultats_df %>%
    arrange(RMSE) %>%
    mutate(Rang_RMSE = row_number()) %>%
    select(Modele, Rang_RMSE, RMSE, MAPE, R_squared)
  
  # Classer par MAPE
  classement_mape <- resultats_df %>%
    arrange(MAPE) %>%
    mutate(Rang_MAPE = row_number()) %>%
    select(Modele, Rang_MAPE)
  
  # Classer par R²
  classement_r2 <- resultats_df %>%
    arrange(desc(R_squared)) %>%
    mutate(Rang_R2 = row_number()) %>%
    select(Modele, Rang_R2)
  
  # Combiner
  tableau_final <- classement_rmse %>%
    left_join(classement_mape, by = "Modele") %>%
    left_join(classement_r2, by = "Modele") %>%
    mutate(
      Score_global = (Rang_RMSE + Rang_MAPE + Rang_R2) / 3
    ) %>%
    arrange(Score_global)
  
  cat("📊 CLASSEMENT FINAL:\n\n")
  print(tableau_final)
  cat("\n")
  
  # Sauvegarder
  if (!dir.exists("data")) {
    dir.create("data", recursive = TRUE)
  }
  
  write.csv(tableau_final, get_path_modeles("comparaison_modeles_finale.csv"), row.names = FALSE)
  cat("✅ Tableau sauvegardé:", get_path_modeles("comparaison_modeles_finale.csv"), "\n\n")
  
  return(tableau_final)
}

# =============================================================================
# FONCTION PRINCIPALE
# =============================================================================

executer_comparaison_avancee <- function() {
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 COMPARAISON AVANCÉE DES MODÈLES\n")
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
  
  # Comparer tous les modèles
  resultats <- comparer_tous_modeles(consommation_ts)
  
  if (!is.null(resultats) && !is.null(resultats$resultats)) {
    # Créer tableau récapitulatif
    tableau <- creer_tableau_recapitulatif(resultats$resultats)
    
    cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
    cat("✅ COMPARAISON AVANCÉE TERMINÉE\n")
    cat(paste0(rep("=", 80), collapse = ""), "\n\n")
    
    cat("📁 Fichiers créés:\n")
    cat("   - figures/comparaison_modeles_complete.png\n")
    cat("   - figures/comparaison_multimetriques.png\n")
    cat("   - data/comparaison_modeles_finale.csv\n\n")
    
    return(list(
      resultats = resultats,
      tableau = tableau
    ))
  }
  
  return(NULL)
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
  fichier_log <- paste0("logs/comparaison_modeles_avancee_", timestamp, ".log")
  
  # Ouvrir le fichier de log
  sink(fichier_log, split = TRUE)  # split = TRUE pour afficher ET sauvegarder
  
  cat("=", paste0(rep("=", 78), collapse = ""), "=\n", sep = "")
  cat("📝 LOG D'EXÉCUTION - COMPARAISON AVANCÉE DES MODÈLES\n")
  cat("=", paste0(rep("=", 78), collapse = ""), "=\n", sep = "")
  cat("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
  cat("Script: comparaison_modeles_avancee.R\n\n")
  
  tryCatch({
    resultats <- executer_comparaison_avancee()
    
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

