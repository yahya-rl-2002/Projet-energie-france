# =============================================================================
# ANALYSE DE SCÉNARIOS
# =============================================================================
# Génération de prévisions sous différents scénarios
# (scénario optimiste, réaliste, pessimiste)

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
# DÉFINIR LES SCÉNARIOS
# =============================================================================

definir_scenarios <- function() {
  scenarios <- list(
    optimiste = list(
      nom = "Optimiste",
      description = "Consommation en baisse (-5% par rapport à la tendance)",
      facteur = 0.95,
      couleur = "green"
    ),
    realiste = list(
      nom = "Réaliste",
      description = "Tendance actuelle maintenue",
      facteur = 1.0,
      couleur = "blue"
    ),
    pessimiste = list(
      nom = "Pessimiste",
      description = "Consommation en hausse (+5% par rapport à la tendance)",
      facteur = 1.05,
      couleur = "red"
    )
  )
  
  return(scenarios)
}

# =============================================================================
# AJUSTER MODÈLE
# =============================================================================

ajuster_modele <- function(train_ts, nom_modele = "ARIMA_auto") {
  cat("📊 Ajustement du modèle", nom_modele, "...\n")
  
  tryCatch({
    if (nom_modele == "TBATS") {
      modele <- tbats(train_ts)
    } else if (nom_modele == "ETS") {
      modele <- ets(train_ts)
    } else {
      modele <- auto.arima(train_ts, seasonal = TRUE, stepwise = TRUE)
    }
    
    cat("✅ Modèle ajusté\n\n")
    return(modele)
  }, error = function(e) {
    cat("⚠️ Erreur:", e$message, "\n")
    return(auto.arima(train_ts, seasonal = TRUE, stepwise = TRUE))
  })
}

# =============================================================================
# GÉNÉRER PRÉVISIONS PAR SCÉNARIO
# =============================================================================

generer_previsions_scenarios <- function(modele, train_ts, scenarios, horizon = 168) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("🔮 GÉNÉRATION DE PRÉVISIONS PAR SCÉNARIO\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Prévision de base
  cat("📊 Génération de la prévision de base...\n")
  prev_base <- forecast(modele, h = horizon, level = 95)
  
  # Gérer la structure de lower/upper (peut être vecteur ou matrice)
  if (is.matrix(prev_base$lower)) {
    lower_base <- as.numeric(prev_base$lower[, ncol(prev_base$lower)])
    upper_base <- as.numeric(prev_base$upper[, ncol(prev_base$upper)])
  } else {
    lower_base <- as.numeric(prev_base$lower)
    upper_base <- as.numeric(prev_base$upper)
  }
  
  resultats <- list()
  
  for (nom_scenario in names(scenarios)) {
    scenario <- scenarios[[nom_scenario]]
    cat("📊 Scénario", scenario$nom, "...\n")
    cat("   Description:", scenario$description, "\n")
    
    # Ajuster la prévision selon le facteur du scénario
    prev_scenario <- list(
      mean = as.numeric(prev_base$mean) * scenario$facteur,
      lower = lower_base * scenario$facteur,
      upper = upper_base * scenario$facteur
    )
    
    resultats[[nom_scenario]] <- list(
      nom = scenario$nom,
      description = scenario$description,
      facteur = scenario$facteur,
      couleur = scenario$couleur,
      prevision = prev_scenario$mean,
      lower = prev_scenario$lower,
      upper = prev_scenario$upper
    )
    
    cat("   ✅ Prévision générée\n\n")
  }
  
  return(list(
    base = prev_base,
    scenarios = resultats
  ))
}

# =============================================================================
# VISUALISER SCÉNARIOS
# =============================================================================

visualiser_scenarios <- function(train_ts, previsions_scenarios, horizon_afficher = 168) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 CRÉATION DES GRAPHIQUES DE SCÉNARIOS\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Prendre les dernières observations pour contexte
  n_context <- min(200, length(train_ts))
  train_recent <- tail(train_ts, n_context)
  
  freq <- frequency(train_ts)
  dernier_index <- time(train_ts)[length(train_ts)]
  
  # Données historiques
  hist_time <- tail(time(train_ts), n_context)
  hist_values <- as.numeric(train_recent)
  
  # Créer dataframe pour ggplot
  df_plot <- data.frame(
    Time = c(hist_time, seq(from = dernier_index + 1/freq, by = 1/freq, length.out = horizon_afficher)),
    Value = c(hist_values, rep(NA, horizon_afficher)),
    Type = c(rep("Historique", length(hist_values)), rep("Prévision", horizon_afficher))
  )
  
  # Ajouter prévisions pour chaque scénario
  for (nom_scenario in names(previsions_scenarios$scenarios)) {
    scenario <- previsions_scenarios$scenarios[[nom_scenario]]
    prev_values <- scenario$prevision[1:horizon_afficher]
    prev_lower <- scenario$lower[1:horizon_afficher]
    prev_upper <- scenario$upper[1:horizon_afficher]
    
    # Ajouter colonnes pour ce scénario
    df_plot[[paste0("Prev_", nom_scenario)]] <- c(rep(NA, length(hist_values)), prev_values)
    df_plot[[paste0("Lower_", nom_scenario)]] <- c(rep(NA, length(hist_values)), prev_lower)
    df_plot[[paste0("Upper_", nom_scenario)]] <- c(rep(NA, length(hist_values)), prev_upper)
  }
  
  # Graphique principal
  p <- ggplot(df_plot, aes(x = Time)) +
    geom_line(aes(y = Value, color = "Historique"), size = 1) +
    geom_vline(xintercept = dernier_index, linetype = "dashed", color = "gray")
  
  # Ajouter prévisions pour chaque scénario
  couleurs_scenarios <- c(
    optimiste = "green",
    realiste = "blue",
    pessimiste = "red"
  )
  
  for (nom_scenario in names(previsions_scenarios$scenarios)) {
    scenario <- previsions_scenarios$scenarios[[nom_scenario]]
    col_prev <- paste0("Prev_", nom_scenario)
    col_lower <- paste0("Lower_", nom_scenario)
    col_upper <- paste0("Upper_", nom_scenario)
    
    p <- p +
      geom_ribbon(aes_string(ymin = col_lower, ymax = col_upper), 
                 alpha = 0.2, fill = couleurs_scenarios[nom_scenario]) +
      geom_line(aes_string(y = col_prev, color = paste0("'", scenario$nom, "'")), 
                size = 1.2, linetype = "dashed")
  }
  
  p <- p +
    labs(
      title = "Prévisions par Scénario - Horizon 1 semaine",
      x = "Temps",
      y = "Consommation",
      color = "Type"
    ) +
    theme_minimal() +
    scale_color_manual(
      values = c(
        "Historique" = "black",
        "Optimiste" = "green",
        "Réaliste" = "blue",
        "Pessimiste" = "red"
      )
    ) +
    theme(legend.position = "bottom")
  
  # Sauvegarder
  png("figures/previsions_scenarios.png", width = 1400, height = 800)
  print(p)
  dev.off()
  
  cat("✅ Graphique sauvegardé: figures/previsions_scenarios.png\n\n")
  
  # Graphique comparatif des moyennes
  df_comparatif <- data.frame(
    Scenario = character(),
    Horizon = integer(),
    Prevision = numeric()
  )
  
  for (nom_scenario in names(previsions_scenarios$scenarios)) {
    scenario <- previsions_scenarios$scenarios[[nom_scenario]]
    df_comparatif <- rbind(df_comparatif, data.frame(
      Scenario = scenario$nom,
      Horizon = 1:horizon_afficher,
      Prevision = scenario$prevision[1:horizon_afficher]
    ))
  }
  
  p_comparatif <- ggplot(df_comparatif, aes(x = Horizon, y = Prevision, color = Scenario)) +
    geom_line(size = 1.2) +
    labs(
      title = "Comparaison des Scénarios",
      x = "Horizon (heures)",
      y = "Consommation Prévue",
      color = "Scénario"
    ) +
    theme_minimal() +
    scale_color_manual(values = c("Optimiste" = "green", "Réaliste" = "blue", "Pessimiste" = "red"))
  
  png("figures/comparaison_scenarios.png", width = 1200, height = 600)
  print(p_comparatif)
  dev.off()
  
  cat("✅ Graphique comparatif sauvegardé: figures/comparaison_scenarios.png\n\n")
}

# =============================================================================
# EXPORTER SCÉNARIOS
# =============================================================================

exporter_scenarios <- function(previsions_scenarios, horizon = 168) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("💾 EXPORTATION DES SCÉNARIOS\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  if (!dir.exists("data")) {
    dir.create("data", recursive = TRUE)
  }
  
  # Créer dataframe avec tous les scénarios
  resultats_df <- list()
  
  for (nom_scenario in names(previsions_scenarios$scenarios)) {
    scenario <- previsions_scenarios$scenarios[[nom_scenario]]
    
    df_scenario <- data.frame(
      Scenario = scenario$nom,
      Horizon = 1:horizon,
      Prevision = scenario$prevision[1:horizon],
      Lower_95 = scenario$lower[1:horizon],
      Upper_95 = scenario$upper[1:horizon],
      Facteur = scenario$facteur
    )
    
    resultats_df[[nom_scenario]] <- df_scenario
  }
  
  # Combiner tous les scénarios
  scenarios_combines <- do.call(rbind, resultats_df)
  
  # Sauvegarder
  write.csv(scenarios_combines, get_path_previsions("previsions_scenarios.csv"), row.names = FALSE)
  
  cat("✅ Scénarios sauvegardés:", get_path_previsions("previsions_scenarios.csv"), "\n")
  cat("   Total:", nrow(scenarios_combines), "prévisions\n\n")
  
  # Statistiques par scénario
  stats_scenarios <- scenarios_combines %>%
    group_by(Scenario) %>%
    summarise(
      Moyenne = mean(Prevision, na.rm = TRUE),
      Min = min(Prevision, na.rm = TRUE),
      Max = max(Prevision, na.rm = TRUE),
      Ecart_type = sd(Prevision, na.rm = TRUE)
    )
  
  write.csv(stats_scenarios, get_path_previsions("statistiques_scenarios.csv"), row.names = FALSE)
  cat("✅ Statistiques sauvegardées:", get_path_previsions("statistiques_scenarios.csv"), "\n\n")
  
  print(stats_scenarios)
  cat("\n")
  
  return(list(
    previsions = scenarios_combines,
    statistiques = stats_scenarios
  ))
}

# =============================================================================
# FONCTION PRINCIPALE
# =============================================================================

executer_analyse_scenarios <- function() {
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  cat("🔮 ANALYSE DE SCÉNARIOS\n")
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
  
  # Définir scénarios
  scenarios <- definir_scenarios()
  
  cat("📊 Scénarios définis:\n")
  for (nom in names(scenarios)) {
    cat("   -", scenarios[[nom]]$nom, ":", scenarios[[nom]]$description, "\n")
  }
  cat("\n")
  
  # Ajuster modèle
  modele <- ajuster_modele(train_ts, "ARIMA_auto")
  
  # Générer prévisions par scénario
  horizon <- 168  # 1 semaine
  previsions_scenarios <- generer_previsions_scenarios(modele, train_ts, scenarios, horizon)
  
  # Visualiser
  visualiser_scenarios(train_ts, previsions_scenarios, horizon)
  
  # Exporter
  resultats_export <- exporter_scenarios(previsions_scenarios, horizon)
  
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("✅ ANALYSE DE SCÉNARIOS TERMINÉE\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  cat("📁 Fichiers créés:\n")
  cat("   - figures/previsions_scenarios.png\n")
  cat("   - figures/comparaison_scenarios.png\n")
  cat("   - data/previsions_scenarios.csv\n")
  cat("   - data/statistiques_scenarios.csv\n\n")
  
  return(list(
    modele = modele,
    scenarios = scenarios,
    previsions = previsions_scenarios,
    resultats = resultats_export
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
  fichier_log <- paste0("logs/analyse_scenarios_", timestamp, ".log")
  
  sink(fichier_log, split = TRUE)
  
  cat("=", paste0(rep("=", 78), collapse = ""), "=\n", sep = "")
  cat("📝 LOG D'EXÉCUTION - ANALYSE DE SCÉNARIOS\n")
  cat("=", paste0(rep("=", 78), collapse = ""), "=\n", sep = "")
  cat("Date:", format(Sys.time(), "%Y-%m-%d %H:%M:%S"), "\n")
  cat("Script: analyse_scenarios.R\n\n")
  
  tryCatch({
    resultats <- executer_analyse_scenarios()
    
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

