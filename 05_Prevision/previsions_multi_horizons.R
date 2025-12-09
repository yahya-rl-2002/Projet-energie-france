# =============================================================================
# PRÉVISIONS MULTI-HORIZONS
# =============================================================================
# Génération de prévisions pour différents horizons temporels
# (1h, 6h, 12h, 24h, 48h, 72h, 1 semaine, 1 mois)

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
# CHARGER LE MEILLEUR MODÈLE
# =============================================================================

charger_meilleur_modele <- function() {
  chemin_comparaison <- "data/comparaison_modeles_finale.csv"
  if (file.exists(chemin_comparaison)) {
    comparaison <- read.csv(chemin_comparaison)
    meilleur_modele_nom <- comparaison$Modele[1]
    cat("📊 Meilleur modèle identifié:", meilleur_modele_nom, "\n\n")
    return(meilleur_modele_nom)
  }
  return("ARIMA_auto")  # Par défaut
}

# =============================================================================
# AJUSTER LE MODÈLE
# =============================================================================

ajuster_modele <- function(train_ts, nom_modele) {
  cat("📊 Ajustement du modèle", nom_modele, "...\n")
  
  modele <- NULL
  
  tryCatch({
    if (nom_modele == "TBATS") {
      modele <- tbats(train_ts)
    } else if (nom_modele == "ETS") {
      modele <- ets(train_ts)
    } else if (nom_modele == "ARIMA_auto") {
      modele <- auto.arima(train_ts, seasonal = TRUE, stepwise = TRUE)
    } else if (nom_modele == "STL_ARIMA") {
      stl_decomp <- stl(train_ts, s.window = "periodic")
      arima_remainder <- auto.arima(stl_decomp$time.series[, "remainder"], stepwise = TRUE)
      modele <- list(stl = stl_decomp, arima = arima_remainder)
    } else {
      # Par défaut ARIMA
      modele <- auto.arima(train_ts, seasonal = TRUE, stepwise = TRUE)
    }
    
    cat("✅ Modèle ajusté\n\n")
    return(modele)
  }, error = function(e) {
    cat("⚠️ Erreur lors de l'ajustement:", e$message, "\n")
    cat("   Utilisation d'ARIMA par défaut...\n")
    return(auto.arima(train_ts, seasonal = TRUE, stepwise = TRUE))
  })
}

# =============================================================================
# GÉNÉRER PRÉVISIONS MULTI-HORIZONS
# =============================================================================

generer_previsions_multi_horizons <- function(modele, train_ts, horizons = c(1, 6, 12, 24, 48, 72, 168, 720)) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("🔮 GÉNÉRATION DE PRÉVISIONS MULTI-HORIZONS\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  resultats <- list()
  
  for (h in horizons) {
    cat("📊 Horizon:", h, "pas (", h, "h)...\n")
    
    tryCatch({
      # Générer prévision selon le type de modèle
      if (is.list(modele) && "stl" %in% names(modele)) {
        # STL + ARIMA
        stl_future <- forecast(modele$stl, h = h)
        arima_future <- forecast(modele$arima, h = h)
        prev <- list(
          mean = stl_future$mean + arima_future$mean,
          lower = stl_future$lower + arima_future$lower,
          upper = stl_future$upper + arima_future$upper
        )
      } else {
        prev <- forecast(modele, h = h, level = c(80, 95))
      }
      
      resultats[[paste0("h", h)]] <- list(
        horizon = h,
        prevision = as.numeric(prev$mean),
        lower_80 = as.numeric(prev$lower[, 1]),
        upper_80 = as.numeric(prev$upper[, 1]),
        lower_95 = as.numeric(prev$lower[, 2]),
        upper_95 = as.numeric(prev$upper[, 2])
      )
      
      cat("   ✅ Prévision générée\n")
    }, error = function(e) {
      cat("   ⚠️ Erreur:", e$message, "\n")
    })
    
    cat("\n")
  }
  
  return(resultats)
}

# =============================================================================
# VISUALISER PRÉVISIONS MULTI-HORIZONS
# =============================================================================

visualiser_previsions_multi_horizons <- function(train_ts, previsions, horizons_afficher = c(24, 48, 72, 168)) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 CRÉATION DES GRAPHIQUES\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  plots <- list()
  
  # Prendre les dernières observations pour contexte
  n_context <- min(200, length(train_ts))
  train_recent <- tail(train_ts, n_context)
  
  for (h in horizons_afficher) {
    nom_h <- paste0("h", h)
    
    if (nom_h %in% names(previsions)) {
      prev_data <- previsions[[nom_h]]
      
      # Créer séquence temporelle
      freq <- frequency(train_ts)
      dernier_index <- time(train_ts)[length(train_ts)]
      
      # Données historiques
      hist_time <- tail(time(train_ts), n_context)
      hist_values <- as.numeric(train_recent)
      
      # Prévisions
      prev_time <- seq(from = dernier_index + 1/freq, by = 1/freq, length.out = h)
      prev_values <- prev_data$prevision
      prev_lower <- prev_data$lower_95
      prev_upper <- prev_data$upper_95
      
      # Créer dataframe pour ggplot
      df_plot <- data.frame(
        Time = c(hist_time, prev_time),
        Value = c(hist_values, prev_values),
        Lower = c(rep(NA, length(hist_values)), prev_lower),
        Upper = c(rep(NA, length(hist_values)), prev_upper),
        Type = c(rep("Historique", length(hist_values)), rep("Prévision", length(prev_values)))
      )
      
      p <- ggplot(df_plot, aes(x = Time, y = Value)) +
        geom_line(aes(color = Type), size = 1) +
        geom_ribbon(aes(ymin = Lower, ymax = Upper), alpha = 0.2, fill = "blue") +
        geom_vline(xintercept = dernier_index, linetype = "dashed", color = "red") +
        labs(
          title = paste("Prévision - Horizon", h, "h"),
          x = "Temps",
          y = "Consommation",
          color = "Type"
        ) +
        theme_minimal() +
        scale_color_manual(values = c("Historique" = "black", "Prévision" = "blue"))
      
      plots[[nom_h]] <- p
      
      cat("✅ Graphique créé pour horizon", h, "h\n")
    }
  }
  
  # Sauvegarder graphiques
  if (length(plots) > 0) {
    # Graphique combiné
    png("figures/previsions_multi_horizons.png", width = 1600, height = 2000)
    do.call(grid.arrange, c(plots, ncol = 1))
    dev.off()
    
    cat("✅ Graphique combiné sauvegardé: figures/previsions_multi_horizons.png\n\n")
  }
}

# =============================================================================
# EXPORTER PRÉVISIONS
# =============================================================================

exporter_previsions <- function(previsions) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("💾 EXPORTATION DES PRÉVISIONS\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  if (!dir.exists("data")) {
    dir.create("data", recursive = TRUE)
  }
  
  # Créer dataframe avec toutes les prévisions
  resultats_df <- list()
  
  for (nom_h in names(previsions)) {
    prev_data <- previsions[[nom_h]]
    h <- prev_data$horizon
    
    df_h <- data.frame(
      Horizon = h,
      Pas = 1:h,
      Prevision = prev_data$prevision,
      Lower_80 = prev_data$lower_80,
      Upper_80 = prev_data$upper_80,
      Lower_95 = prev_data$lower_95,
      Upper_95 = prev_data$upper_95
    )
    
    resultats_df[[nom_h]] <- df_h
  }
  
  # Combiner tous les horizons
  previsions_combinees <- do.call(rbind, resultats_df)
  
  # Sauvegarder
  write.csv(previsions_combinees, get_path_previsions("previsions_multi_horizons.csv"), row.names = FALSE)
  
  cat("✅ Prévisions sauvegardées:", get_path_previsions("previsions_multi_horizons.csv"), "\n")
  cat("   Total:", nrow(previsions_combinees), "prévisions\n\n")
  
  # Sauvegarder aussi par horizon
  for (nom_h in names(resultats_df)) {
    fichier_h <- get_path_previsions(paste0("previsions_h", resultats_df[[nom_h]]$Horizon[1], ".csv"))
    write.csv(resultats_df[[nom_h]], fichier_h, row.names = FALSE)
    cat("   -", fichier_h, "\n")
  }
  
  cat("\n")
  
  return(previsions_combinees)
}

# =============================================================================
# FONCTION PRINCIPALE
# =============================================================================

executer_previsions_multi_horizons <- function() {
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  cat("🔮 PRÉVISIONS MULTI-HORIZONS\n")
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
  
  # Utiliser toutes les données pour l'entraînement (pas de test ici)
  train_ts <- consommation_ts
  
  # Charger le meilleur modèle
  meilleur_modele_nom <- charger_meilleur_modele()
  
  # Ajuster le modèle
  modele <- ajuster_modele(train_ts, meilleur_modele_nom)
  
  # Générer prévisions pour différents horizons
  horizons <- c(1, 6, 12, 24, 48, 72, 168, 720)  # 1h, 6h, 12h, 24h, 48h, 72h, 1 semaine, 1 mois
  previsions <- generer_previsions_multi_horizons(modele, train_ts, horizons)
  
  # Visualiser
  visualiser_previsions_multi_horizons(train_ts, previsions, horizons_afficher = c(24, 48, 72, 168))
  
  # Exporter
  previsions_df <- exporter_previsions(previsions)
  
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("✅ PRÉVISIONS MULTI-HORIZONS TERMINÉES\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  cat("📁 Fichiers créés:\n")
  cat("   - figures/previsions_multi_horizons.png\n")
  cat("   - data/previsions_multi_horizons.csv\n")
  cat("   - data/previsions_h*.csv (par horizon)\n\n")
  
  return(list(
    modele = modele,
    previsions = previsions,
    previsions_df = previsions_df
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
  fichier_log <- paste0("logs/previsions_multi_horizons_", timestamp, ".log")
  
  # Ouvrir le fichier de log
  sink(fichier_log, split = TRUE)
  
  cat("=", paste0(rep("=", 78), collapse = ""), "=\n", sep = "")
  cat("📝 LOG D'EXÉCUTION - PRÉVISIONS MULTI-HORIZONS\n")
  cat("=", paste0(rep("=", 78), collapse = ""), "=\n", sep = "")
  cat("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
  cat("Script: previsions_multi_horizons.R\n\n")
  
  tryCatch({
    resultats <- executer_previsions_multi_horizons()
    
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

