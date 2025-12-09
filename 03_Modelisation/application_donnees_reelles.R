# =============================================================================
# APPLICATION SUR DONNÉES RÉELLES
# =============================================================================
# Application de toutes les méthodes sur vos données (defi1, defi2, defi3)
# + données publiques collectées

library(tidyverse)
library(forecast)
library(tseries)
library(urca)
library(ggplot2)
library(lubridate)

# Charger les fonctions de modélisation
chemins_modeles <- c(
  "modeles_series_temporelles.R",
  "03_Modelisation/modeles_series_temporelles.R",
  "../03_Modelisation/modeles_series_temporelles.R",
  "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION/03_Modelisation/modeles_series_temporelles.R"
)
chemin_modeles <- NULL
for (chemin in chemins_modeles) {
  if (file.exists(chemin)) {
    source(chemin)
    chemin_modeles <- chemin
    break
  }
}
if (is.null(chemin_modeles)) {
  stop("❌ Fichier modeles_series_temporelles.R non trouvé")
}

# Charger les données combinées
chemins_combinaison <- c(
  "../01_Donnees/combinaison_donnees.R",
  "01_Donnees/combinaison_donnees.R",
  "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION/01_Donnees/combinaison_donnees.R"
)
chemin_combinaison <- NULL
for (chemin in chemins_combinaison) {
  if (file.exists(chemin)) {
    source(chemin)
    chemin_combinaison <- chemin
    break
  }
}
if (is.null(chemin_combinaison)) {
  stop("❌ Fichier combinaison_donnees.R non trouvé")
}

# =============================================================================
# CHARGER ET PRÉPARER LES DONNÉES
# =============================================================================

cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("🚀 APPLICATION SUR DONNÉES RÉELLES\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

# Charger dataset combiné
# Chercher le dataset dans plusieurs emplacements possibles
chemins_dataset <- c(
  "data/dataset_complet.csv",
  "../data/dataset_complet.csv",
  "01_Donnees/data/dataset_complet.csv",
  "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION/data/dataset_complet.csv"
)

chemin_dataset <- NULL
for (chemin in chemins_dataset) {
  if (file.exists(chemin)) {
    chemin_dataset <- chemin
    break
  }
}

if (!is.null(chemin_dataset)) {
  cat("📂 Chargement dataset combiné...\n")
  df <- read.csv(chemin_dataset, stringsAsFactors = FALSE)
  df$Date <- as.POSIXct(df$Date)
  cat("✅ Dataset chargé:", nrow(df), "observations\n")
  cat("   Source:", chemin_dataset, "\n\n")
} else {
  cat("⚠️ Dataset combiné non trouvé. Création...\n")
  # Aller dans le bon dossier pour que combiner_toutes_donnees fonctionne
  dossier_actuel <- getwd()
  if (!grepl("01_Donnees", dossier_actuel)) {
    if (file.exists("../01_Donnees")) {
      setwd("../01_Donnees")
    } else if (file.exists("01_Donnees")) {
      setwd("01_Donnees")
    }
  }
  df <- combiner_toutes_donnees()
  # Revenir au dossier modélisation
  setwd(dossier_actuel)
}

# Créer série temporelle
consommation_ts <- ts(df$Consommation, 
                     frequency = 24,  # Données horaires
                     start = c(year(min(df$Date)), 
                              yday(min(df$Date))))

cat("📊 Série temporelle créée:\n")
cat("   Observations:", length(consommation_ts), "\n")
cat("   Période:", start(consommation_ts)[1], "-", end(consommation_ts)[1], "\n")
cat("   Fréquence:", frequency(consommation_ts), "h\n\n")

# =============================================================================
# ANALYSE EXPLORATOIRE
# =============================================================================

cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("📊 ANALYSE EXPLORATOIRE\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

# Créer dossiers si nécessaire
if (!dir.exists("../figures")) {
  dir.create("../figures", recursive = TRUE)
}
if (!dir.exists("../data")) {
  dir.create("../data", recursive = TRUE)
}

# Analyse complète
resultats_analyse <- analyser_serie_temporelle(consommation_ts, 
                                               "Consommation Electrique France")

# =============================================================================
# DIVISION TRAIN/TEST
# =============================================================================

cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
cat("✂️ DIVISION TRAIN/TEST (80% / 20%)\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

# =============================================================================
# DIVISION TRAIN/TEST
# =============================================================================

cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
cat("✂️ DIVISION TRAIN/TEST (80% / 20%)\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

n_total <- length(consommation_ts)
n_train <- floor(n_total * 0.8)

# Extraire les valeurs et recréer les séries temporelles
train <- ts(consommation_ts[1:n_train], 
           frequency = frequency(consommation_ts),
           start = start(consommation_ts))

test <- ts(consommation_ts[(n_train + 1):n_total], 
          frequency = frequency(consommation_ts),
          start = time(consommation_ts)[n_train + 1])

cat("   Train:", length(train), "observations\n")
cat("   Test:", length(test), "observations\n\n")

cat("   Train:", length(train), "observations\n")
cat("   Test:", length(test), "observations\n\n")

# =============================================================================
# AJUSTEMENT DES MODÈLES
# =============================================================================

cat(paste0(rep("=", 80), collapse = ""), "\n")
cat("🔧 AJUSTEMENT DES MODÈLES\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

modeles <- list()

# 1. AR(2)
cat("1. AR(2)\n")
modeles[["AR(2)"]] <- ajuster_AR(train, ordre = 2)

# 2. MA(2)
cat("\n2. MA(2)\n")
modeles[["MA(2)"]] <- ajuster_MA(train, ordre = 2)

# 3. ARMA(2,2)
cat("\n3. ARMA(2,2)\n")
modeles[["ARMA(2,2)"]] <- ajuster_ARMA(train, p = 2, q = 2)

# 4. ARIMA Auto
cat("\n4. ARIMA Auto\n")
modeles[["ARIMA_auto"]] <- ajuster_ARIMA_auto(train)

# 5. SARIMA Auto
cat("\n5. SARIMA Auto (période = 24h)\n")
modeles[["SARIMA_auto"]] <- ajuster_SARIMA_auto(train, periode_saisonniere = 24)

# 6. SARIMAX (si variables exogènes disponibles)
if ("Temperature" %in% colnames(df) && !all(is.na(df$Temperature))) {
  cat("\n6. SARIMAX avec Température\n")
  
  # Préparer variables exogènes (aligner avec train)
  temp_train <- df$Temperature[1:length(train)]
  temp_test <- df$Temperature[(length(train)+1):n_total]
  
  # Vérifier qu'il y a des valeurs non-NA
  if (sum(!is.na(temp_train)) > 100) {
    # Remplacer NA par interpolation si nécessaire
    if (sum(is.na(temp_train)) > 0) {
      temp_train <- zoo::na.approx(temp_train, na.rm = FALSE)
      temp_train <- zoo::na.locf(temp_train, na.rm = FALSE)
    }
    
    # Ajuster SARIMAX
    modeles[["SARIMAX_temp"]] <- ajuster_SARIMAX(
      train,
      variables_exogenes = as.matrix(temp_train),
      ordre = c(1, 1, 1),
      ordre_saisonnier = c(1, 1, 1),
      periode = 24
    )
  } else {
    cat("⚠️ Pas assez de données de température pour SARIMAX\n")
  }
}

# =============================================================================
# COMPARAISON DES MODÈLES
# =============================================================================

cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
cat("📊 COMPARAISON DES MODÈLES\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

# Préparer variables exogènes futures pour SARIMAX si disponible
xreg_futur <- NULL
if ("Temperature" %in% colnames(df) && "SARIMAX_temp" %in% names(modeles)) {
  temp_test <- df$Temperature[(length(train)+1):n_total]
  if (sum(!is.na(temp_test)) > 0) {
    # Remplacer NA par interpolation si nécessaire
    if (sum(is.na(temp_test)) > 0) {
      temp_test <- zoo::na.approx(temp_test, na.rm = FALSE)
      temp_test <- zoo::na.locf(temp_test, na.rm = FALSE)
    }
    xreg_futur <- as.matrix(temp_test)
    cat("📊 Variables exogènes futures préparées pour SARIMAX\n")
  }
}

comparaison <- comparer_modeles(modeles, test, xreg_futur = xreg_futur)

# Afficher meilleur modèle (exclure ceux avec NA pour RMSE)
comparaison_valide <- comparaison[!is.na(comparaison$RMSE), ]
if (nrow(comparaison_valide) > 0) {
  meilleur_nom <- comparaison_valide$Modele[1]
  cat("\n🏆 MEILLEUR MODÈLE:", meilleur_nom, "\n")
  cat("   RMSE:", comparaison_valide$RMSE[1], "\n")
  cat("   MAPE:", round(comparaison_valide$MAPE[1], 2), "%\n\n")
} else {
  # Si aucun modèle n'a de RMSE, utiliser celui avec le meilleur AIC
  meilleur_nom <- comparaison$Modele[which.min(comparaison$AIC)]
  cat("\n🏆 MEILLEUR MODÈLE (par AIC):", meilleur_nom, "\n")
  cat("   AIC:", comparaison$AIC[which.min(comparaison$AIC)], "\n\n")
}

# =============================================================================
# DIAGNOSTICS DU MEILLEUR MODÈLE
# =============================================================================

meilleur_modele <- modeles[[meilleur_nom]]
diagnostics_residus(meilleur_modele, meilleur_nom)

# =============================================================================
# PRÉVISIONS
# =============================================================================

cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
cat("🔮 PRÉVISIONS\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

# Prévision sur période de test
# Vérifier si le modèle utilise des variables exogènes
utilise_xreg <- !is.null(meilleur_modele$xreg) || !is.null(meilleur_modele$call$xreg)
if (utilise_xreg && !is.null(xreg_futur)) {
  xreg_forecast <- as.matrix(xreg_futur[1:length(test), , drop = FALSE])
  prevision <- forecast(meilleur_modele, h = length(test), xreg = xreg_forecast)
} else {
  prevision <- forecast(meilleur_modele, h = length(test))
}

# Visualisation
chemin_figures <- get_figures_path()
png(paste0(chemin_figures, "/prevision_finale.png"), width = 1600, height = 800)
autoplot(consommation_ts) +
  autolayer(prevision, series = "Prévision", PI = TRUE) +
  autolayer(test, series = "Réel (test)") +
  labs(title = paste("Prévision -", meilleur_nom),
       subtitle = if (nrow(comparaison_valide) > 0) {
         paste("RMSE =", round(comparaison_valide$RMSE[1], 2))
       } else {
         paste("AIC =", round(comparaison$AIC[which.min(comparaison$AIC)], 2))
       },
       y = "Consommation (MW)",
       x = "Temps") +
  theme_minimal()
dev.off()

cat("✅ Prévisions sauvegardées\n")

# Prévision future (prochaines 24h)
cat("\n📅 Prévision pour les prochaines 24h...\n")
tryCatch({
  # Vérifier si le modèle utilise des variables exogènes pour la prévision future
  if (utilise_xreg && !is.null(xreg_futur) && nrow(xreg_futur) >= 24) {
    # Utiliser les dernières valeurs de température disponibles
    xreg_future <- as.matrix(xreg_futur[1:24, , drop = FALSE])
    prevision_future <- forecast(meilleur_modele, h = 24, xreg = xreg_future)
  } else {
    prevision_future <- forecast(meilleur_modele, h = 24)
  }
  
  cat("   Prochaine heure:", round(prevision_future$mean[1], 2), "MW\n")
  # Vérifier le format de lower/upper
  if (is.matrix(prevision_future$lower)) {
    cat("   Intervalle 95%: [", 
        round(prevision_future$lower[1, 2], 2), ", ",
        round(prevision_future$upper[1, 2], 2), "]\n\n")
  } else if (length(prevision_future$lower) > 1) {
    cat("   Intervalle 95%: [", 
        round(prevision_future$lower[1], 2), ", ",
        round(prevision_future$upper[1], 2), "]\n\n")
  }
}, error = function(e) {
  cat("⚠️ Erreur lors de la prévision future:", e$message, "\n")
})

# Créer dossier data s'il n'existe pas
if (!dir.exists("../data")) {
  dir.create("../data", recursive = TRUE)
}

# Sauvegarder prévisions
tryCatch({
  # Vérifier le format de lower/upper pour la sauvegarde
  if (exists("prevision_future") && !is.null(prevision_future)) {
    if (is.matrix(prevision_future$lower)) {
      df_previsions <- data.frame(
        Heure = 1:24,
        Prevision = prevision_future$mean,
        Lower_95 = prevision_future$lower[, 2],
        Upper_95 = prevision_future$upper[, 2]
      )
    } else if (length(prevision_future$lower) >= 24) {
      df_previsions <- data.frame(
        Heure = 1:24,
        Prevision = prevision_future$mean,
        Lower_95 = prevision_future$lower[1:24],
        Upper_95 = prevision_future$upper[1:24]
      )
    } else {
      df_previsions <- data.frame(
        Heure = 1:24,
        Prevision = prevision_future$mean,
        Lower_95 = NA,
        Upper_95 = NA
      )
    }
    write.csv(df_previsions, "../data/previsions_24h.csv", row.names = FALSE)
    cat("✅ Prévisions 24h sauvegardées\n")
  }
}, error = function(e) {
  cat("⚠️ Erreur lors de la sauvegarde des prévisions:", e$message, "\n")
})

# Sauvegarder comparaison des modèles
tryCatch({
  write.csv(comparaison, "../data/comparaison_modeles.csv", row.names = FALSE)
  cat("✅ Comparaison des modèles sauvegardée\n")
}, error = function(e) {
  cat("⚠️ Erreur lors de la sauvegarde de la comparaison:", e$message, "\n")
})

# =============================================================================
# RÉSUMÉ FINAL
# =============================================================================

cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
cat("✅ ANALYSE TERMINÉE\n")
cat(paste0(rep("=", 80), collapse = ""), "\n\n")

cat("📊 Résultats sauvegardés dans:\n")
cat("   - figures/: Graphiques\n")
cat("   - data/previsions_24h.csv: Prévisions futures\n")
cat("   - data/comparaison_modeles.csv: Comparaison\n\n")

# Afficher le meilleur modèle (utiliser les variables déjà définies)
cat("🏆 Meilleur modèle:", meilleur_nom, "\n")
if (nrow(comparaison_valide) > 0) {
  cat("   RMSE:", round(comparaison_valide$RMSE[1], 2), "\n")
  cat("   MAPE:", round(comparaison_valide$MAPE[1], 2), "%\n\n")
} else {
  cat("   AIC:", round(comparaison$AIC[which.min(comparaison$AIC)], 2), "\n\n")
}

