# =============================================================================
# ANALYSE DE SAISONNALITÉ AVANCÉE
# =============================================================================
# Analyse détaillée des patterns saisonniers

# Configurer miroir CRAN pour éviter les prompts interactifs
options(repos = c(CRAN = "https://cran.rstudio.com/"))

library(tidyverse)

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
  stop("❌ Fichier chemins_resultats.R non trouvé")
}
library(lubridate)
library(ggplot2)
library(forecast)
library(gridExtra)

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
  cat("✅ Dataset chargé:", nrow(df), "observations\n\n")
  return(df)
}

# =============================================================================
# DÉCOMPOSITION SAISONNIÈRE AVANCÉE
# =============================================================================

decomposition_saisonniere_avancee <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 DÉCOMPOSITION SAISONNIÈRE AVANCÉE\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Préparer série temporelle
  df_ts <- df %>%
    filter(!is.na(Consommation), !is.na(Date)) %>%
    arrange(Date) %>%
    select(Date, Consommation)
  
  if (nrow(df_ts) < 100) {
    cat("⚠️ Pas assez de données pour la décomposition\n\n")
    return(NULL)
  }
  
  # Créer série temporelle (fréquence horaire = 24*365.25)
  freq_horaire <- 24 * 365.25
  
  # Échantillonner si trop de données
  if (nrow(df_ts) > 50000) {
    df_ts <- df_ts %>%
      slice(seq(1, n(), by = max(1, floor(n() / 50000))))
  }
  
  ts_data <- ts(df_ts$Consommation, 
                frequency = freq_horaire,
                start = c(year(min(df_ts$Date)), yday(min(df_ts$Date))))
  
  # Décomposition STL (plus robuste)
  cat("📊 Décomposition STL...\n")
  
  tryCatch({
    decomp_stl <- stl(ts_data, s.window = "periodic", robust = TRUE)
    
    # Graphique de décomposition
    png("figures/decomposition_saisonniere_avancee.png", 
        width = 1400, height = 1000)
    plot(decomp_stl, main = "Décomposition Saisonnière Avancée (STL)")
    dev.off()
    
    cat("   ✅ Décomposition sauvegardée: figures/decomposition_saisonniere_avancee.png\n\n")
    
    # Statistiques de la saisonnalité
    saisonnalite <- decomp_stl$time.series[, "seasonal"]
    cat("📊 Statistiques de la saisonnalité:\n")
    cat("   Amplitude:", round(max(saisonnalite) - min(saisonnalite), 2), "MW\n")
    cat("   Écart-type:", round(sd(saisonnalite), 2), "MW\n\n")
    
    return(decomp_stl)
    
  }, error = function(e) {
    cat("   ⚠️ Erreur décomposition STL:", e$message, "\n")
    cat("   → Essai avec décomposition classique...\n")
    
    tryCatch({
      decomp <- decompose(ts_data)
      
      png("figures/decomposition_saisonniere.png", 
          width = 1400, height = 1000)
      plot(decomp, main = "Décomposition Saisonnière")
      dev.off()
      
      cat("   ✅ Décomposition sauvegardée\n\n")
      return(decomp)
    }, error = function(e2) {
      cat("   ❌ Erreur décomposition classique:", e2$message, "\n\n")
      return(NULL)
    })
  })
}

# =============================================================================
# ANALYSE PAR SAISON MÉTÉOROLOGIQUE
# =============================================================================

analyser_par_saison <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("🌍 ANALYSE PAR SAISON MÉTÉOROLOGIQUE\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  if (!"Saison" %in% colnames(df)) {
    cat("⚠️ Variable Saison non disponible\n\n")
    return(NULL)
  }
  
  # Statistiques par saison
  stats_saison <- df %>%
    filter(!is.na(Saison), !is.na(Consommation)) %>%
    group_by(Saison) %>%
    summarise(
      Consommation_moyenne = mean(Consommation, na.rm = TRUE),
      Consommation_mediane = median(Consommation, na.rm = TRUE),
      Consommation_min = min(Consommation, na.rm = TRUE),
      Consommation_max = max(Consommation, na.rm = TRUE),
      Temperature_moyenne = mean(Temperature, na.rm = TRUE),
      Nombre_observations = n(),
      .groups = "drop"
    ) %>%
    arrange(Consommation_moyenne)
  
  print(stats_saison)
  cat("\n")
  
  # Graphique par saison
  p_saison <- df %>%
    filter(!is.na(Saison)) %>%
    ggplot(aes(x = Saison, y = Consommation, fill = Saison)) +
    geom_boxplot() +
    labs(title = "Distribution de la Consommation par Saison",
         x = "Saison", y = "Consommation (MW)") +
    theme_minimal() +
    scale_fill_brewer(palette = "Set2")
  
  png("figures/consommation_par_saison.png", width = 1000, height = 600)
  print(p_saison)
  dev.off()
  
  cat("✅ Graphique sauvegardé: figures/consommation_par_saison.png\n\n")
  
  # Sauvegarder
  write.csv(stats_saison, get_path_analyses("stats_saisonnalite.csv"), row.names = FALSE)
  
  return(stats_saison)
}

# =============================================================================
# PATTERNS HEBDOMADAIRES
# =============================================================================

analyser_patterns_hebdomadaires <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📅 PATTERNS HEBDOMADAIRES\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  if (!"JourSemaine" %in% colnames(df)) {
    cat("⚠️ Variable JourSemaine non disponible\n\n")
    return(NULL)
  }
  
  # Statistiques par jour de semaine
  stats_jour <- df %>%
    filter(!is.na(JourSemaine), !is.na(Consommation)) %>%
    mutate(JourNom = case_when(
      JourSemaine == 1 ~ "Dimanche",
      JourSemaine == 2 ~ "Lundi",
      JourSemaine == 3 ~ "Mardi",
      JourSemaine == 4 ~ "Mercredi",
      JourSemaine == 5 ~ "Jeudi",
      JourSemaine == 6 ~ "Vendredi",
      JourSemaine == 7 ~ "Samedi"
    )) %>%
    group_by(JourNom) %>%
    summarise(
      Consommation_moyenne = mean(Consommation, na.rm = TRUE),
      Nombre_observations = n(),
      .groups = "drop"
    ) %>%
    mutate(JourNom = factor(JourNom, 
                            levels = c("Lundi", "Mardi", "Mercredi", "Jeudi", 
                                      "Vendredi", "Samedi", "Dimanche"))) %>%
    arrange(JourNom)
  
  print(stats_jour)
  cat("\n")
  
  # Graphique
  p_jour <- stats_jour %>%
    ggplot(aes(x = JourNom, y = Consommation_moyenne, fill = JourNom)) +
    geom_bar(stat = "identity") +
    labs(title = "Consommation Moyenne par Jour de la Semaine",
         x = "Jour", y = "Consommation Moyenne (MW)") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1)) +
    scale_fill_brewer(palette = "Set3")
  
  png("figures/pattern_hebdomadaire.png", width = 1000, height = 600)
  print(p_jour)
  dev.off()
  
  cat("✅ Graphique sauvegardé: figures/pattern_hebdomadaire.png\n\n")
  
  return(stats_jour)
}

# =============================================================================
# PATTERNS MENSUELS
# =============================================================================

analyser_patterns_mensuels <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📅 PATTERNS MENSUELS\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  if (!"Mois" %in% colnames(df)) {
    cat("⚠️ Variable Mois non disponible\n\n")
    return(NULL)
  }
  
  # Statistiques par mois
  stats_mois <- df %>%
    filter(!is.na(Mois), !is.na(Consommation)) %>%
    mutate(MoisNom = month.abb[Mois]) %>%
    group_by(Mois, MoisNom) %>%
    summarise(
      Consommation_moyenne = mean(Consommation, na.rm = TRUE),
      Temperature_moyenne = mean(Temperature, na.rm = TRUE),
      Nombre_observations = n(),
      .groups = "drop"
    ) %>%
    arrange(Mois) %>%
    mutate(MoisNom = factor(MoisNom, levels = month.abb))
  
  print(stats_mois)
  cat("\n")
  
  # Graphique
  p_mois <- stats_mois %>%
    ggplot(aes(x = MoisNom, y = Consommation_moyenne, fill = Temperature_moyenne)) +
    geom_bar(stat = "identity") +
    scale_fill_gradient2(low = "blue", mid = "white", high = "red", 
                        midpoint = mean(stats_mois$Temperature_moyenne, na.rm = TRUE)) +
    labs(title = "Consommation Moyenne par Mois (colorée par température)",
         x = "Mois", y = "Consommation Moyenne (MW)",
         fill = "Température") +
    theme_minimal() +
    theme(axis.text.x = element_text(angle = 45, hjust = 1))
  
  png("figures/pattern_mensuel.png", width = 1200, height = 600)
  print(p_mois)
  dev.off()
  
  cat("✅ Graphique sauvegardé: figures/pattern_mensuel.png\n\n")
  
  return(stats_mois)
}

# =============================================================================
# PATTERNS HORAIRES
# =============================================================================

analyser_patterns_horaires <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("🕐 PATTERNS HORAIRES\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  if (!"Heure" %in% colnames(df)) {
    cat("⚠️ Variable Heure non disponible\n\n")
    return(NULL)
  }
  
  # Statistiques par heure
  stats_heure <- df %>%
    filter(!is.na(Heure), !is.na(Consommation)) %>%
    group_by(Heure) %>%
    summarise(
      Consommation_moyenne = mean(Consommation, na.rm = TRUE),
      Consommation_mediane = median(Consommation, na.rm = TRUE),
      Nombre_observations = n(),
      .groups = "drop"
    ) %>%
    arrange(Heure)
  
  print(stats_heure)
  cat("\n")
  
  # Graphique
  p_heure <- stats_heure %>%
    ggplot(aes(x = Heure, y = Consommation_moyenne)) +
    geom_line(color = "steelblue", size = 1.2) +
    geom_point(color = "red", size = 2) +
    labs(title = "Consommation Moyenne par Heure de la Journée",
         x = "Heure", y = "Consommation Moyenne (MW)") +
    theme_minimal() +
    scale_x_continuous(breaks = 0:23)
  
  png("figures/pattern_horaire.png", width = 1200, height = 600)
  print(p_heure)
  dev.off()
  
  cat("✅ Graphique sauvegardé: figures/pattern_horaire.png\n\n")
  
  return(stats_heure)
}

# =============================================================================
# IMPACT DES VACANCES
# =============================================================================

analyser_impact_vacances <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("🎉 IMPACT DES JOURS FÉRIÉS ET WEEK-ENDS\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Comparer jours fériés vs jours normaux
  if ("EstFerie" %in% colnames(df)) {
    cat("📊 Comparaison Jours Fériés vs Jours Normaux:\n\n")
    
    comparaison_ferie <- df %>%
      filter(!is.na(EstFerie)) %>%
      group_by(EstFerie) %>%
      summarise(
        Consommation_moyenne = mean(Consommation, na.rm = TRUE),
        Nombre_observations = n(),
        .groups = "drop"
      )
    
    print(comparaison_ferie)
    
    # Calculer différence
    if (nrow(comparaison_ferie) == 2) {
      diff_ferie <- (comparaison_ferie$Consommation_moyenne[comparaison_ferie$EstFerie == 1] - 
                     comparaison_ferie$Consommation_moyenne[comparaison_ferie$EstFerie == 0]) /
                    comparaison_ferie$Consommation_moyenne[comparaison_ferie$EstFerie == 0] * 100
      cat("\n   📊 Différence:", round(diff_ferie, 2), "%\n\n")
    }
  }
  
  # Comparer week-ends vs jours ouvrables
  if ("EstWeekend" %in% colnames(df)) {
    cat("📊 Comparaison Week-ends vs Jours Ouvrables:\n\n")
    
    comparaison_weekend <- df %>%
      filter(!is.na(EstWeekend)) %>%
      group_by(EstWeekend) %>%
      summarise(
        Consommation_moyenne = mean(Consommation, na.rm = TRUE),
        Nombre_observations = n(),
        .groups = "drop"
      )
    
    print(comparaison_weekend)
    
    if (nrow(comparaison_weekend) == 2) {
      diff_weekend <- (comparaison_weekend$Consommation_moyenne[comparaison_weekend$EstWeekend == 1] - 
                       comparaison_weekend$Consommation_moyenne[comparaison_weekend$EstWeekend == 0]) /
                      comparaison_weekend$Consommation_moyenne[comparaison_weekend$EstWeekend == 0] * 100
      cat("\n   📊 Différence:", round(diff_weekend, 2), "%\n\n")
    }
  }
}

# =============================================================================
# FONCTION PRINCIPALE
# =============================================================================

analyser_saisonnalite_complete <- function() {
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  cat("🌍 ANALYSE DE SAISONNALITÉ AVANCÉE\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Charger les données
  df <- charger_dataset()
  
  # 1. Décomposition saisonnière
  decomp <- decomposition_saisonniere_avancee(df)
  
  # 2. Analyse par saison
  stats_saison <- analyser_par_saison(df)
  
  # 3. Patterns hebdomadaires
  stats_jour <- analyser_patterns_hebdomadaires(df)
  
  # 4. Patterns mensuels
  stats_mois <- analyser_patterns_mensuels(df)
  
  # 5. Patterns horaires
  stats_heure <- analyser_patterns_horaires(df)
  
  # 6. Impact vacances
  analyser_impact_vacances(df)
  
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("✅ ANALYSE DE SAISONNALITÉ TERMINÉE\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  cat("📁 Fichiers créés:\n")
  cat("   - figures/decomposition_saisonniere_avancee.png\n")
  cat("   - figures/consommation_par_saison.png\n")
  cat("   - figures/pattern_hebdomadaire.png\n")
  cat("   - figures/pattern_mensuel.png\n")
  cat("   - figures/pattern_horaire.png\n")
  cat("   - data/stats_saisonnalite.csv\n\n")
  
  return(list(
    decomposition = decomp,
    stats_saison = stats_saison,
    stats_jour = stats_jour,
    stats_mois = stats_mois,
    stats_heure = stats_heure
  ))
}

# =============================================================================
# EXÉCUTION
# =============================================================================

if (!interactive()) {
  projet_dir <- "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION"
  if (dir.exists(projet_dir)) {
    setwd(projet_dir)
  }
  
  resultats <- analyser_saisonnalite_complete()
}

