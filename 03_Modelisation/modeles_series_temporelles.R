# =============================================================================
# MÉTHODES DE SÉRIES TEMPORELLES EN R
# =============================================================================
# Application complète de toutes les méthodes classiques

library(forecast)
library(tseries)
library(urca)
library(fpp3)
library(ggplot2)
library(dplyr)

# =============================================================================
# FONCTION HELPER POUR LE CHEMIN DES FIGURES
# =============================================================================

# Déterminer le chemin du dossier figures
get_figures_path <- function() {
  # Essayer différents chemins possibles
  chemins_possibles <- c(
    "../figures",           # Depuis 03_Modelisation/
    "figures",              # Dans le répertoire actuel
    "../../figures",        # Depuis un sous-dossier
    "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION/figures"  # Chemin absolu
  )
  
  # Trouver le premier chemin qui existe
  for (chemin in chemins_possibles) {
    if (dir.exists(chemin)) {
      return(chemin)
    }
  }
  
  # Si aucun n'existe, créer le dossier dans le répertoire parent
  chemin_figures <- "../figures"
  if (!dir.exists(chemin_figures)) {
    dir.create(chemin_figures, recursive = TRUE)
  }
  
  return(chemin_figures)
}

# =============================================================================
# CLASSE POUR ANALYSE DE SÉRIES TEMPORELLES
# =============================================================================

# Fonction principale d'analyse
analyser_serie_temporelle <- function(serie, nom = "Série") {
  
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 ANALYSE DE SÉRIE TEMPORELLE:", nom, "\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Convertir en ts si nécessaire
  if (!is.ts(serie)) {
    serie <- ts(serie, frequency = 24)  # 24h pour données horaires
  }
  
  resultats <- list()
  resultats$serie <- serie
  resultats$nom <- nom
  
  # ===========================================================================
  # 1. STATISTIQUES DESCRIPTIVES
  # ===========================================================================
  cat("1. STATISTIQUES DESCRIPTIVES\n")
  cat(paste0(rep("-", 80), collapse = ""), "\n")
  cat("   Observations:", length(serie), "\n")
  cat("   Moyenne:", mean(serie, na.rm = TRUE), "\n")
  cat("   Écart-type:", sd(serie, na.rm = TRUE), "\n")
  cat("   Min:", min(serie, na.rm = TRUE), "\n")
  cat("   Max:", max(serie, na.rm = TRUE), "\n")
  cat("   Médiane:", median(serie, na.rm = TRUE), "\n\n")
  
  # ===========================================================================
  # 2. TEST DE STATIONNARITÉ (Dickey-Fuller)
  # ===========================================================================
  cat("2. TEST DE STATIONNARITÉ (Dickey-Fuller Augmenté)\n")
  cat(paste0(rep("-", 80), collapse = ""), "\n")
  
  test_adf <- ur.df(serie, type = "trend", lags = 10)
  resultats$test_adf <- test_adf
  
  # Afficher résultats
  cat("   Statistique ADF:", test_adf@teststat[1], "\n")
  cat("   Valeurs critiques:\n")
  for (i in 1:3) {
    cat("     ", names(test_adf@cval)[i], ":", test_adf@cval[i], "\n")
  }
  
  # Interprétation
  if (test_adf@teststat[1] < test_adf@cval[2]) {
    cat("   ✅ Série STATIONNAIRE (p-value < 0.05)\n")
    resultats$stationnaire <- TRUE
  } else {
    cat("   ❌ Série NON-STATIONNAIRE (p-value >= 0.05)\n")
    cat("      → Nécessite différenciation pour ARIMA\n")
    resultats$stationnaire <- FALSE
  }
  cat("\n")
  
  # ===========================================================================
  # 3. ANALYSE ACF/PACF
  # ===========================================================================
  cat("3. ANALYSE ACF ET PACF\n")
  cat(paste0(rep("-", 80), collapse = ""), "\n")
  
  # Calculer ACF et PACF
  acf_vals <- acf(serie, plot = FALSE, lag.max = 48)
  pacf_vals <- pacf(serie, plot = FALSE, lag.max = 48)
  
  resultats$acf <- acf_vals
  resultats$pacf <- pacf_vals
  
  # Visualisation
  chemin_figures <- get_figures_path()
  nom_fichier <- paste0(chemin_figures, "/acf_pacf_", gsub(" ", "_", nom), ".png")
  png(nom_fichier, width = 1200, height = 800)
  par(mfrow = c(2, 1))
  acf(serie, lag.max = 48, main = paste("ACF -", nom))
  pacf(serie, lag.max = 48, main = paste("PACF -", nom))
  dev.off()
  
  cat("   ✅ Graphiques ACF/PACF sauvegardés\n")
  cat("   💡 Interprétation:\n")
  cat("      - ACF décroît lentement → besoin différenciation\n")
  cat("      - PACF se coupe après lag p → ordre AR = p\n")
  cat("      - ACF se coupe après lag q → ordre MA = q\n\n")
  
  # ===========================================================================
  # 4. DÉCOMPOSITION
  # ===========================================================================
  cat("4. DÉCOMPOSITION SAISONNIÈRE\n")
  cat(paste0(rep("-", 80), collapse = ""), "\n")
  
  # Décomposition additive
  decomp_add <- decompose(serie, type = "additive")
  resultats$decomposition_additive <- decomp_add
  
  # Décomposition multiplicative
  decomp_mult <- decompose(serie, type = "multiplicative")
  resultats$decomposition_multiplicative <- decomp_mult
  
  # Visualisation
  chemin_figures <- get_figures_path()
  nom_fichier <- paste0(chemin_figures, "/decomposition_", gsub(" ", "_", nom), ".png")
  png(nom_fichier, width = 1400, height = 1000)
  plot(decomp_add)
  dev.off()
  
  cat("   ✅ Décomposition sauvegardée\n")
  cat("   Composantes: Tendance + Saisonnalité + Résidus\n\n")
  
  # ===========================================================================
  # 5. MOYENNE MOBILE
  # ===========================================================================
  cat("5. MOYENNE MOBILE\n")
  cat(paste0(rep("-", 80), collapse = ""), "\n")
  
  ma_24 <- ma(serie, order = 24)  # 24h
  ma_168 <- ma(serie, order = 168)  # 7 jours
  
  resultats$ma_24 <- ma_24
  resultats$ma_168 <- ma_168
  
  # Visualisation
  chemin_figures <- get_figures_path()
  nom_fichier <- paste0(chemin_figures, "/moving_average_", gsub(" ", "_", nom), ".png")
  png(nom_fichier, width = 1400, height = 600)
  autoplot(serie, series = "Originale") +
    autolayer(ma_24, series = "MA(24h)") +
    autolayer(ma_168, series = "MA(7j)") +
    labs(title = paste("Moyennes Mobiles -", nom),
         y = "Valeur") +
    theme_minimal()
  dev.off()
  
  cat("   ✅ Moyennes mobiles calculées (24h et 7j)\n\n")
  
  return(resultats)
}

# =============================================================================
# FONCTIONS POUR CHAQUE MODÈLE
# =============================================================================

# -----------------------------------------------------------------------------
# AR (AutoRegressive)
# -----------------------------------------------------------------------------
ajuster_AR <- function(serie, ordre = 1) {
  cat("📊 Ajustement AR(", ordre, ")...\n")
  
  # Utiliser Arima avec ordre (p, 0, 0)
  modele <- Arima(serie, order = c(ordre, 0, 0))
  
  cat("✅ AR(", ordre, ") ajusté\n")
  print(summary(modele))
  
  return(modele)
}

# -----------------------------------------------------------------------------
# MA (Moving Average)
# -----------------------------------------------------------------------------
ajuster_MA <- function(serie, ordre = 1) {
  cat("📊 Ajustement MA(", ordre, ")...\n")
  
  # Utiliser Arima avec ordre (0, 0, q)
  modele <- Arima(serie, order = c(0, 0, ordre))
  
  cat("✅ MA(", ordre, ") ajusté\n")
  print(summary(modele))
  
  return(modele)
}

# -----------------------------------------------------------------------------
# ARMA
# -----------------------------------------------------------------------------
ajuster_ARMA <- function(serie, p = 1, q = 1) {
  cat("📊 Ajustement ARMA(", p, ",", q, ")...\n")
  
  modele <- Arima(serie, order = c(p, 0, q))
  
  cat("✅ ARMA(", p, ",", q, ") ajusté\n")
  print(summary(modele))
  
  return(modele)
}

# -----------------------------------------------------------------------------
# ARIMA (Auto)
# -----------------------------------------------------------------------------
ajuster_ARIMA_auto <- function(serie, max_p = 5, max_d = 2, max_q = 5) {
  cat("📊 Recherche automatique ARIMA...\n")
  
  # Auto-ARIMA (meilleur que forecast::auto.arima)
  modele <- auto.arima(serie,
                      max.p = max_p,
                      max.d = max_d,
                      max.q = max_q,
                      seasonal = FALSE,
                      stepwise = TRUE,
                      approximation = FALSE,
                      trace = TRUE)
  
  cat("✅ ARIMA", modele$arma, "trouvé\n")
  print(summary(modele))
  
  return(modele)
}

# -----------------------------------------------------------------------------
# SARIMA (Saisonnier)
# -----------------------------------------------------------------------------
ajuster_SARIMA_auto <- function(serie, periode_saisonniere = 24,
                                max_p = 3, max_d = 2, max_q = 3,
                                max_P = 2, max_D = 1, max_Q = 2) {
  cat("📊 Recherche automatique SARIMA (période =", periode_saisonniere, ")...\n")
  
  modele <- auto.arima(serie,
                      max.p = max_p,
                      max.d = max_d,
                      max.q = max_q,
                      max.P = max_P,
                      max.D = max_D,
                      max.Q = max_Q,
                      seasonal = TRUE,
                      stepwise = TRUE,
                      approximation = FALSE,
                      trace = TRUE)
  
  cat("✅ SARIMA", modele$arma, "trouvé\n")
  print(summary(modele))
  
  return(modele)
}

# -----------------------------------------------------------------------------
# SARIMAX (Avec variables exogènes)
# -----------------------------------------------------------------------------
ajuster_SARIMAX <- function(serie, variables_exogenes,
                           ordre = c(1, 1, 1),
                           ordre_saisonnier = c(1, 1, 1),
                           periode = 24) {
  cat("📊 Ajustement SARIMAX avec variables exogènes...\n")
  if (is.matrix(variables_exogenes) || is.data.frame(variables_exogenes)) {
    cat("   Variables:", paste(colnames(variables_exogenes), collapse = ", "), "\n")
  } else {
    cat("   Variables: 1 variable exogène\n")
  }
  
  # Convertir variables_exogenes en matrice si nécessaire
  if (!is.matrix(variables_exogenes)) {
    variables_exogenes <- as.matrix(variables_exogenes)
  }
  
  # Vérifier que la longueur correspond
  if (nrow(variables_exogenes) != length(serie)) {
    stop("❌ La longueur des variables exogènes doit correspondre à la série")
  }
  
  # Format correct pour seasonal: list(order = c(P, D, Q), period = s)
  modele <- tryCatch({
    Arima(serie,
          order = ordre,
          seasonal = list(order = ordre_saisonnier, period = periode),
          xreg = variables_exogenes)
  }, error = function(e) {
    cat("⚠️ Erreur lors de l'ajustement SARIMAX:", e$message, "\n")
    cat("   Tentative avec ARIMA simple (sans saisonnalité)...\n")
    Arima(serie,
          order = ordre,
          xreg = variables_exogenes)
  })
  
  cat("✅ SARIMAX ajusté\n")
  print(summary(modele))
  
  return(modele)
}

# =============================================================================
# COMPARAISON DE MODÈLES
# =============================================================================

comparer_modeles <- function(liste_modeles, serie_test, xreg_futur = NULL) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 COMPARAISON DES MODÈLES\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  resultats <- data.frame(
    Modele = character(),
    RMSE = numeric(),
    MAE = numeric(),
    MAPE = numeric(),
    AIC = numeric(),
    BIC = numeric(),
    stringsAsFactors = FALSE
  )
  
  for (nom_modele in names(liste_modeles)) {
    modele <- liste_modeles[[nom_modele]]
    
    # Vérifier si le modèle utilise des variables exogènes
    utilise_xreg <- !is.null(modele$xreg) || !is.null(modele$call$xreg)
    
    # Prédiction
    tryCatch({
      if (utilise_xreg) {
        # Modèle avec variables exogènes
        if (!is.null(xreg_futur)) {
          # Vérifier que la longueur correspond
          if (nrow(xreg_futur) >= length(serie_test)) {
            xreg_forecast <- as.matrix(xreg_futur[1:length(serie_test), , drop = FALSE])
            prevision <- forecast(modele, h = length(serie_test), xreg = xreg_forecast)
          } else {
            cat("⚠️", nom_modele, ": Pas assez de valeurs futures pour xreg, utilisation de la moyenne\n")
            # Utiliser la moyenne des variables exogènes comme approximation
            if (is.matrix(modele$xreg) || is.data.frame(modele$xreg)) {
              xreg_mean <- matrix(rep(colMeans(modele$xreg, na.rm = TRUE), length(serie_test)), 
                                 nrow = length(serie_test), byrow = TRUE)
            } else {
              xreg_mean <- matrix(rep(mean(modele$xreg, na.rm = TRUE), length(serie_test)), 
                                 nrow = length(serie_test), ncol = 1)
            }
            prevision <- forecast(modele, h = length(serie_test), xreg = xreg_mean)
          }
        } else {
          cat("⚠️", nom_modele, ": Modèle avec xreg mais pas de valeurs futures fournies, saut de la prévision\n")
          # Utiliser seulement AIC/BIC pour la comparaison
          aic <- tryCatch(AIC(modele), error = function(e) NA)
          bic <- tryCatch(BIC(modele), error = function(e) NA)
          resultats <- rbind(resultats, data.frame(
            Modele = nom_modele,
            RMSE = NA,
            MAE = NA,
            MAPE = NA,
            AIC = aic,
            BIC = bic
          ))
          next
        }
      } else {
        # Modèle sans variables exogènes
        prevision <- forecast(modele, h = length(serie_test))
      }
      
      # Métriques
      erreurs <- serie_test - prevision$mean
      rmse <- sqrt(mean(erreurs^2, na.rm = TRUE))
      mae <- mean(abs(erreurs), na.rm = TRUE)
      mape <- mean(abs(erreurs / serie_test), na.rm = TRUE) * 100
      
      # AIC, BIC
      aic <- tryCatch(AIC(modele), error = function(e) NA)
      bic <- tryCatch(BIC(modele), error = function(e) NA)
      
      resultats <- rbind(resultats, data.frame(
        Modele = nom_modele,
        RMSE = rmse,
        MAE = mae,
        MAPE = mape,
        AIC = aic,
        BIC = bic
      ))
    }, error = function(e) {
      cat("⚠️", nom_modele, ": Erreur lors de la prévision -", e$message, "\n")
      # Utiliser seulement AIC/BIC
      aic <- tryCatch(AIC(modele), error = function(e) NA)
      bic <- tryCatch(BIC(modele), error = function(e) NA)
      resultats <<- rbind(resultats, data.frame(
        Modele = nom_modele,
        RMSE = NA,
        MAE = NA,
        MAPE = NA,
        AIC = aic,
        BIC = bic
      ))
    })
  }
  
  # Trier par RMSE (en mettant les NA à la fin)
  resultats$RMSE_ordre <- ifelse(is.na(resultats$RMSE), Inf, resultats$RMSE)
  resultats <- resultats[order(resultats$RMSE_ordre), ]
  resultats$RMSE_ordre <- NULL
  
  cat("Résultats:\n")
  print(resultats)
  
  # Visualisation
  chemin_figures <- get_figures_path()
  nom_fichier <- paste0(chemin_figures, "/comparaison_modeles.png")
  png(nom_fichier, width = 1400, height = 800)
  par(mfrow = c(1, 2))
  barplot(resultats$RMSE, names.arg = resultats$Modele, 
         main = "RMSE par Modèle", las = 2)
  barplot(resultats$MAPE, names.arg = resultats$Modele,
         main = "MAPE par Modèle", las = 2)
  dev.off()
  
  cat("\n✅ Comparaison sauvegardée\n")
  
  return(resultats)
}

# =============================================================================
# DIAGNOSTICS DES RÉSIDUS
# =============================================================================

diagnostics_residus <- function(modele, nom_modele = "Modèle") {
  cat("\n📊 DIAGNOSTICS DES RÉSIDUS:", nom_modele, "\n")
  cat(paste0(rep("-", 80), collapse = ""), "\n")
  
  residus <- residuals(modele)
  
  # Test de Ljung-Box
  test_lb <- Box.test(residus, lag = 10, type = "Ljung-Box")
  cat("Test de Ljung-Box (H0: pas d'autocorrélation):\n")
  cat("  Statistique:", test_lb$statistic, "\n")
  cat("  p-value:", test_lb$p.value, "\n")
  
  if (test_lb$p.value > 0.05) {
    cat("  ✅ Résidus non corrélés (p-value > 0.05)\n")
  } else {
    cat("  ❌ Résidus corrélés (p-value <= 0.05)\n")
  }
  
  # Visualisation
  chemin_figures <- get_figures_path()
  nom_fichier <- paste0(chemin_figures, "/residus_", gsub(" ", "_", nom_modele), ".png")
  png(nom_fichier, width = 1400, height = 1000)
  par(mfrow = c(2, 2))
  
  # Résidus dans le temps
  plot(residus, main = "Résidus dans le temps", ylab = "Résidus")
  
  # Histogramme
  hist(residus, main = "Distribution des résidus", 
      xlab = "Résidus", breaks = 30)
  
  # ACF des résidus
  acf(residus, main = "ACF des résidus", lag.max = 20)
  
  # Q-Q plot
  qqnorm(residus, main = "Q-Q Plot (Normalité)")
  qqline(residus)
  
  dev.off()
  
  cat("✅ Graphiques de diagnostics sauvegardés\n")
  
  return(list(residus = residus, test_lb = test_lb))
}

# =============================================================================
# EXEMPLE D'UTILISATION
# =============================================================================

if (FALSE) {  # Mettre TRUE pour exécuter l'exemple
  
  # Charger vos données
  data <- read.csv("defi1.csv", sep = ";")
  consommation <- ts(data$Consommation, frequency = 24)
  
  # Analyse exploratoire
  resultats <- analyser_serie_temporelle(consommation, "Consommation Electrique")
  
  # Ajuster différents modèles
  modeles <- list()
  
  modeles[["AR(2)"]] <- ajuster_AR(consommation, ordre = 2)
  modeles[["MA(2)"]] <- ajuster_MA(consommation, ordre = 2)
  modeles[["ARMA(2,2)"]] <- ajuster_ARMA(consommation, p = 2, q = 2)
  modeles[["ARIMA_auto"]] <- ajuster_ARIMA_auto(consommation)
  modeles[["SARIMA_auto"]] <- ajuster_SARIMA_auto(consommation, periode_saisonniere = 24)
  
  # Comparer
  # Diviser en train/test
  train <- window(consommation, end = length(consommation) * 0.8)
  test <- window(consommation, start = length(consommation) * 0.8 + 1)
  
  comparaison <- comparer_modeles(modeles, test)
  
  # Diagnostics du meilleur modèle
  meilleur_modele <- modeles[[comparaison$Modele[1]]]
  diagnostics_residus(meilleur_modele, comparaison$Modele[1])
  
}

