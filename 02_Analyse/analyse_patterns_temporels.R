# =============================================================================
# ANALYSE DES PATTERNS TEMPORELS
# =============================================================================
# Analyse détaillée des patterns horaires, journaliers, hebdomadaires

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
# PATTERNS HORAIRES DÉTAILLÉS
# =============================================================================

analyser_patterns_horaires_detaille <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("🕐 PATTERNS HORAIRES DÉTAILLÉS\n")
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
      Consommation_min = min(Consommation, na.rm = TRUE),
      Consommation_max = max(Consommation, na.rm = TRUE),
      Consommation_sd = sd(Consommation, na.rm = TRUE),
      Nombre_observations = n(),
      .groups = "drop"
    ) %>%
    arrange(Heure)
  
  cat("📊 Statistiques par heure:\n\n")
  print(stats_heure)
  cat("\n")
  
  # Identifier heures de pointe
  heure_pointe <- stats_heure %>%
    arrange(desc(Consommation_moyenne)) %>%
    head(5)
  
  cat("📊 Top 5 heures de pointe:\n\n")
  print(heure_pointe)
  cat("\n")
  
  # Graphique
  p_heure <- stats_heure %>%
    ggplot(aes(x = Heure, y = Consommation_moyenne)) +
    geom_line(color = "steelblue", size = 1.2) +
    geom_ribbon(aes(ymin = Consommation_moyenne - Consommation_sd,
                    ymax = Consommation_moyenne + Consommation_sd),
                alpha = 0.2, fill = "steelblue") +
    geom_point(color = "red", size = 2) +
    labs(title = "Pattern Horaire de la Consommation",
         subtitle = "Moyenne ± 1 écart-type",
         x = "Heure", y = "Consommation Moyenne (MW)") +
    theme_minimal() +
    scale_x_continuous(breaks = seq(0, 23, 2))
  
  png("figures/pattern_horaire_detaille.png", width = 1200, height = 600)
  print(p_heure)
  dev.off()
  
  cat("✅ Graphique sauvegardé: figures/pattern_horaire_detaille.png\n\n")
  
  return(stats_heure)
}

# =============================================================================
# PATTERNS PAR TYPE DE JOUR
# =============================================================================

analyser_patterns_par_type_jour <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📅 PATTERNS PAR TYPE DE JOUR\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  if (!"TypeJour" %in% colnames(df) || !"Heure" %in% colnames(df)) {
    cat("⚠️ Variables TypeJour ou Heure non disponibles\n\n")
    return(NULL)
  }
  
  # Pattern horaire par type de jour
  pattern_type_jour <- df %>%
    filter(!is.na(TypeJour), !is.na(Heure), !is.na(Consommation)) %>%
    group_by(TypeJour, Heure) %>%
    summarise(
      Consommation_moyenne = mean(Consommation, na.rm = TRUE),
      Nombre_observations = n(),
      .groups = "drop"
    ) %>%
    arrange(TypeJour, Heure)
  
  cat("📊 Pattern horaire par type de jour calculé\n\n")
  
  # Graphique
  p_type_jour <- pattern_type_jour %>%
    ggplot(aes(x = Heure, y = Consommation_moyenne, color = TypeJour)) +
    geom_line(size = 1.2) +
    labs(title = "Pattern Horaire par Type de Jour",
         x = "Heure", y = "Consommation Moyenne (MW)",
         color = "Type de Jour") +
    theme_minimal() +
    scale_x_continuous(breaks = seq(0, 23, 2)) +
    scale_color_brewer(palette = "Set2")
  
  png("figures/pattern_horaire_par_type_jour.png", width = 1400, height = 600)
  print(p_type_jour)
  dev.off()
  
  cat("✅ Graphique sauvegardé: figures/pattern_horaire_par_type_jour.png\n\n")
  
  return(pattern_type_jour)
}

# =============================================================================
# PATTERNS PAR SAISON
# =============================================================================

analyser_patterns_par_saison <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("🌍 PATTERNS PAR SAISON\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  if (!"Saison" %in% colnames(df) || !"Heure" %in% colnames(df)) {
    cat("⚠️ Variables Saison ou Heure non disponibles\n\n")
    return(NULL)
  }
  
  # Pattern horaire par saison
  pattern_saison <- df %>%
    filter(!is.na(Saison), !is.na(Heure), !is.na(Consommation)) %>%
    group_by(Saison, Heure) %>%
    summarise(
      Consommation_moyenne = mean(Consommation, na.rm = TRUE),
      Temperature_moyenne = mean(Temperature, na.rm = TRUE),
      Nombre_observations = n(),
      .groups = "drop"
    ) %>%
    arrange(Saison, Heure)
  
  cat("📊 Pattern horaire par saison calculé\n\n")
  
  # Graphique
  p_saison <- pattern_saison %>%
    ggplot(aes(x = Heure, y = Consommation_moyenne, color = Saison)) +
    geom_line(size = 1.2) +
    labs(title = "Pattern Horaire par Saison",
         x = "Heure", y = "Consommation Moyenne (MW)",
         color = "Saison") +
    theme_minimal() +
    scale_x_continuous(breaks = seq(0, 23, 2)) +
    scale_color_brewer(palette = "Set1")
  
  png("figures/pattern_horaire_par_saison.png", width = 1400, height = 600)
  print(p_saison)
  dev.off()
  
  cat("✅ Graphique sauvegardé: figures/pattern_horaire_par_saison.png\n\n")
  
  return(pattern_saison)
}

# =============================================================================
# PATTERNS PAR COULEUR TEMPO
# =============================================================================

analyser_patterns_par_tempo <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("🎨 PATTERNS PAR COULEUR TEMPO\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  if (!"Couleur_TEMPO" %in% colnames(df) || !"Heure" %in% colnames(df)) {
    cat("⚠️ Variables Couleur_TEMPO ou Heure non disponibles\n\n")
    return(NULL)
  }
  
  # Pattern horaire par couleur TEMPO
  pattern_tempo <- df %>%
    filter(!is.na(Couleur_TEMPO), !is.na(Heure), !is.na(Consommation)) %>%
    filter(Couleur_TEMPO %in% c("Rouge", "Blanc", "Bleu")) %>%
    group_by(Couleur_TEMPO, Heure) %>%
    summarise(
      Consommation_moyenne = mean(Consommation, na.rm = TRUE),
      Nombre_observations = n(),
      .groups = "drop"
    ) %>%
    arrange(Couleur_TEMPO, Heure)
  
  cat("📊 Pattern horaire par couleur TEMPO calculé\n\n")
  
  # Graphique
  p_tempo <- pattern_tempo %>%
    ggplot(aes(x = Heure, y = Consommation_moyenne, color = Couleur_TEMPO)) +
    geom_line(size = 1.2) +
    labs(title = "Pattern Horaire par Couleur TEMPO",
         x = "Heure", y = "Consommation Moyenne (MW)",
         color = "TEMPO") +
    theme_minimal() +
    scale_x_continuous(breaks = seq(0, 23, 2)) +
    scale_color_manual(values = c("Rouge" = "red", "Blanc" = "gray", "Bleu" = "blue"))
  
  png("figures/pattern_horaire_par_tempo.png", width = 1400, height = 600)
  print(p_tempo)
  dev.off()
  
  cat("✅ Graphique sauvegardé: figures/pattern_horaire_par_tempo.png\n\n")
  
  return(pattern_tempo)
}

# =============================================================================
# ÉVOLUTION TEMPORELLE DES PATTERNS
# =============================================================================

analyser_evolution_temporelle <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📈 ÉVOLUTION TEMPORELLE DES PATTERNS\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  if (!"Annee" %in% colnames(df) || !"Mois" %in% colnames(df)) {
    cat("⚠️ Variables temporelles non disponibles\n\n")
    return(NULL)
  }
  
  # Évolution annuelle
  evolution_annuelle <- df %>%
    filter(!is.na(Annee), !is.na(Consommation)) %>%
    group_by(Annee) %>%
    summarise(
      Consommation_moyenne = mean(Consommation, na.rm = TRUE),
      Consommation_max = max(Consommation, na.rm = TRUE),
      Consommation_min = min(Consommation, na.rm = TRUE),
      Nombre_observations = n(),
      .groups = "drop"
    ) %>%
    arrange(Annee)
  
  cat("📊 Évolution annuelle:\n\n")
  print(evolution_annuelle)
  cat("\n")
  
  # Graphique évolution
  p_evolution <- evolution_annuelle %>%
    ggplot(aes(x = Annee, y = Consommation_moyenne)) +
    geom_line(color = "steelblue", size = 1.2) +
    geom_point(color = "red", size = 2) +
    geom_ribbon(aes(ymin = Consommation_min, ymax = Consommation_max),
                alpha = 0.2, fill = "steelblue") +
    labs(title = "Évolution Temporelle de la Consommation",
         subtitle = "Moyenne avec min/max",
         x = "Année", y = "Consommation (MW)") +
    theme_minimal()
  
  png("figures/evolution_temporelle.png", width = 1200, height = 600)
  print(p_evolution)
  dev.off()
  
  cat("✅ Graphique sauvegardé: figures/evolution_temporelle.png\n\n")
  
  return(evolution_annuelle)
}

# =============================================================================
# COMPARAISON DES PATTERNS
# =============================================================================

comparer_patterns <- function(df) {
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 COMPARAISON DES PATTERNS\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Comparer week-ends vs jours ouvrables
  if ("EstWeekend" %in% colnames(df) && "Heure" %in% colnames(df)) {
    cat("📊 Comparaison Week-ends vs Jours Ouvrables:\n\n")
    
    comparaison_weekend <- df %>%
      filter(!is.na(EstWeekend), !is.na(Heure), !is.na(Consommation)) %>%
      mutate(Type = ifelse(EstWeekend == 1, "Week-end", "Jour ouvrable")) %>%
      group_by(Type, Heure) %>%
      summarise(
        Consommation_moyenne = mean(Consommation, na.rm = TRUE),
        .groups = "drop"
      )
    
    p_comparaison <- comparaison_weekend %>%
      ggplot(aes(x = Heure, y = Consommation_moyenne, color = Type)) +
      geom_line(size = 1.2) +
      labs(title = "Comparaison Week-ends vs Jours Ouvrables",
           x = "Heure", y = "Consommation Moyenne (MW)",
           color = "Type") +
      theme_minimal() +
      scale_x_continuous(breaks = seq(0, 23, 2)) +
      scale_color_manual(values = c("Week-end" = "red", "Jour ouvrable" = "blue"))
    
    png("figures/comparaison_weekend.png", width = 1200, height = 600)
    print(p_comparaison)
    dev.off()
    
    cat("✅ Graphique sauvegardé: figures/comparaison_weekend.png\n\n")
  }
  
  # Comparer jours fériés vs jours normaux
  if ("EstFerie" %in% colnames(df) && "Heure" %in% colnames(df)) {
    cat("📊 Comparaison Jours Fériés vs Jours Normaux:\n\n")
    
    comparaison_ferie <- df %>%
      filter(!is.na(EstFerie), !is.na(Heure), !is.na(Consommation)) %>%
      mutate(Type = ifelse(EstFerie == 1, "Jour férié", "Jour normal")) %>%
      group_by(Type, Heure) %>%
      summarise(
        Consommation_moyenne = mean(Consommation, na.rm = TRUE),
        .groups = "drop"
      )
    
    p_comparaison_ferie <- comparaison_ferie %>%
      ggplot(aes(x = Heure, y = Consommation_moyenne, color = Type)) +
      geom_line(size = 1.2) +
      labs(title = "Comparaison Jours Fériés vs Jours Normaux",
           x = "Heure", y = "Consommation Moyenne (MW)",
           color = "Type") +
      theme_minimal() +
      scale_x_continuous(breaks = seq(0, 23, 2)) +
      scale_color_manual(values = c("Jour férié" = "orange", "Jour normal" = "green"))
    
    png("figures/comparaison_ferie.png", width = 1200, height = 600)
    print(p_comparaison_ferie)
    dev.off()
    
    cat("✅ Graphique sauvegardé: figures/comparaison_ferie.png\n\n")
  }
}

# =============================================================================
# FONCTION PRINCIPALE
# =============================================================================

analyser_patterns_temporels_complets <- function() {
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  cat("📊 ANALYSE DES PATTERNS TEMPORELS\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # Charger les données
  df <- charger_dataset()
  
  # 1. Patterns horaires détaillés
  stats_heure <- analyser_patterns_horaires_detaille(df)
  
  # 2. Patterns par type de jour
  pattern_type_jour <- analyser_patterns_par_type_jour(df)
  
  # 3. Patterns par saison
  pattern_saison <- analyser_patterns_par_saison(df)
  
  # 4. Patterns par TEMPO
  pattern_tempo <- analyser_patterns_par_tempo(df)
  
  # 5. Évolution temporelle
  evolution <- analyser_evolution_temporelle(df)
  
  # 6. Comparaisons
  comparer_patterns(df)
  
  # Sauvegarder résultats
  if (!dir.exists("data")) {
    dir.create("data", recursive = TRUE)
  }
  
  if (!is.null(stats_heure)) {
    write.csv(stats_heure, get_path_analyses("pattern_horaire.csv"), row.names = FALSE)
  }
  
  if (!is.null(evolution)) {
    write.csv(evolution, get_path_analyses("evolution_temporelle.csv"), row.names = FALSE)
  }
  
  cat("\n", paste0(rep("=", 80), collapse = ""), "\n")
  cat("✅ ANALYSE DES PATTERNS TEMPORELS TERMINÉE\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  cat("📁 Fichiers créés:\n")
  cat("   - figures/pattern_horaire_detaille.png\n")
  cat("   - figures/pattern_horaire_par_type_jour.png\n")
  cat("   - figures/pattern_horaire_par_saison.png\n")
  cat("   - figures/pattern_horaire_par_tempo.png\n")
  cat("   - figures/evolution_temporelle.png\n")
  cat("   - figures/comparaison_weekend.png\n")
  cat("   - figures/comparaison_ferie.png\n")
  cat("   - data/pattern_horaire.csv\n")
  cat("   - data/evolution_temporelle.csv\n\n")
  
  return(list(
    stats_heure = stats_heure,
    pattern_type_jour = pattern_type_jour,
    pattern_saison = pattern_saison,
    pattern_tempo = pattern_tempo,
    evolution = evolution
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
  
  resultats <- analyser_patterns_temporels_complets()
}

