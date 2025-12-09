# =============================================================================
# CALENDRIER FRANÇAIS POUR PRÉVISION ÉNERGÉTIQUE
# =============================================================================
# Ce script crée un calendrier complet avec :
# - Jours fériés français
# - Calendrier TEMPO (rouge/blanc/bleu)
# - Week-ends
# - Vacances scolaires (optionnel)
# - Variables temporelles (jour, mois, saison, etc.)

library(tidyverse)
library(lubridate)
library(readxl)

# =============================================================================
# CONFIGURATION
# =============================================================================

OUTPUT_DIR <- "data/Calendrier"

# Créer le dossier de sortie
if (!dir.exists(OUTPUT_DIR)) {
  dir.create(OUTPUT_DIR, recursive = TRUE)
  cat("📁 Dossier créé:", OUTPUT_DIR, "\n\n")
}

# Chemin vers les fichiers TEMPO
CHEMIN_TEMPO <- "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION/data/new data"
# Alternative si fichiers dans autre emplacement
if (!dir.exists(CHEMIN_TEMPO)) {
  CHEMIN_TEMPO <- "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/new data"
}

# =============================================================================
# FONCTION : CRÉER CALENDRIER DES JOURS FÉRIÉS FRANÇAIS
# =============================================================================

creer_jours_feries <- function(annee_debut = 2012, annee_fin = 2025) {
  cat("📅 Création du calendrier des jours fériés français...\n")
  cat("   Période:", annee_debut, "-", annee_fin, "\n")
  
  # Créer une séquence de dates
  dates <- seq(as.Date(paste0(annee_debut, "-01-01")), 
               as.Date(paste0(annee_fin, "-12-31")), 
               by = "day")
  
  # Fonction pour calculer Pâques (algorithme de Meeus)
  calculer_paques <- function(annee) {
    a <- annee %% 19
    b <- floor(annee / 100)
    c <- annee %% 100
    d <- floor(b / 4)
    e <- b %% 4
    f <- floor((b + 8) / 25)
    g <- floor((b - f + 1) / 3)
    h <- (19 * a + b - d - g + 15) %% 30
    i <- floor(c / 4)
    k <- c %% 4
    l <- (32 + 2 * e + 2 * i - h - k) %% 7
    m <- floor((a + 11 * h + 22 * l) / 451)
    mois <- floor((h + l - 7 * m + 114) / 31)
    jour <- ((h + l - 7 * m + 114) %% 31) + 1
    return(as.Date(paste(annee, mois, jour, sep = "-")))
  }
  
  # Fonction pour calculer les jours fériés mobiles
  calculer_feries_mobiles <- function(annee) {
    paques <- calculer_paques(annee)
    lundi_paques <- paques + 1
    ascension <- paques + 39
    pentecote <- paques + 49
    lundi_pentecote <- paques + 50
    
    return(list(
      paques = paques,
      lundi_paques = lundi_paques,
      ascension = ascension,
      pentecote = pentecote,
      lundi_pentecote = lundi_pentecote
    ))
  }
  
  # Créer dataframe avec tous les jours fériés
  jours_feries <- tibble()
  
  for (annee in annee_debut:annee_fin) {
    # Jours fériés fixes
    feries_fixes <- tibble(
      Date = as.Date(c(
        paste0(annee, "-01-01"),  # Jour de l'An
        paste0(annee, "-05-01"),  # Fête du Travail
        paste0(annee, "-05-08"),  # Victoire 1945
        paste0(annee, "-07-14"),  # Fête Nationale
        paste0(annee, "-08-15"),  # Assomption
        paste0(annee, "-11-01"),  # Toussaint
        paste0(annee, "-11-11"),  # Armistice 1918
        paste0(annee, "-12-25")   # Noël
      )),
      Nom = c(
        "Jour de l'An",
        "Fête du Travail",
        "Victoire 1945",
        "Fête Nationale",
        "Assomption",
        "Toussaint",
        "Armistice 1918",
        "Noël"
      ),
      Type = "Fixe"
    )
    
    # Jours fériés mobiles
    feries_mobiles <- calculer_feries_mobiles(annee)
    
    feries_mobiles_df <- tibble(
      Date = as.Date(c(
        feries_mobiles$paques,
        feries_mobiles$lundi_paques,
        feries_mobiles$ascension,
        feries_mobiles$pentecote,
        feries_mobiles$lundi_pentecote
      )),
      Nom = c(
        "Pâques",
        "Lundi de Pâques",
        "Ascension",
        "Pentecôte",
        "Lundi de Pentecôte"
      ),
      Type = "Mobile"
    )
    
    # Combiner
    jours_feries <- bind_rows(jours_feries, feries_fixes, feries_mobiles_df)
  }
  
  # Créer un calendrier complet avec indicateur jour férié
  calendrier_complet <- tibble(
    Date = dates
  ) %>%
    mutate(
      Annee = year(Date),
      Mois = month(Date),
      Jour = day(Date),
      JourSemaine = wday(Date, label = TRUE, abbr = FALSE),
      NumeroJourSemaine = wday(Date),
      EstWeekend = NumeroJourSemaine %in% c(1, 7),  # Dimanche = 1, Samedi = 7
      EstFerie = Date %in% jours_feries$Date
    ) %>%
    left_join(
      jours_feries %>% select(Date, Nom_Ferie = Nom, Type_Ferie = Type),
      by = "Date"
    ) %>%
    mutate(
      Nom_Ferie = ifelse(is.na(Nom_Ferie), "", Nom_Ferie),
      Type_Ferie = ifelse(is.na(Type_Ferie), "", Type_Ferie)
    )
  
  cat("   ✅", nrow(calendrier_complet), "jours créés\n")
  cat("   ✅", sum(calendrier_complet$EstFerie), "jours fériés\n")
  cat("   ✅", sum(calendrier_complet$EstWeekend), "week-ends\n\n")
  
  return(calendrier_complet)
}

# =============================================================================
# FONCTION : LIRE CALENDRIER TEMPO
# =============================================================================

lire_calendrier_tempo <- function() {
  cat("📊 Lecture des calendriers TEMPO (Rouge/Blanc/Bleu)...\n")
  
  # Chercher les fichiers TEMPO
  fichiers_tempo <- list.files(
    CHEMIN_TEMPO,
    pattern = "tempo.*\\.xls",
    full.names = TRUE,
    ignore.case = TRUE
  )
  
  if (length(fichiers_tempo) == 0) {
    cat("   ⚠️ Aucun fichier TEMPO trouvé dans", CHEMIN_TEMPO, "\n")
    cat("   💡 Les fichiers doivent être nommés: tempo_YYYY-YYYY.xls\n\n")
    return(NULL)
  }
  
  cat("   📁", length(fichiers_tempo), "fichier(s) trouvé(s)\n\n")
  
  liste_dfs <- list()
  
  for (fichier in fichiers_tempo) {
    cat("   📂", basename(fichier), "\n")
    
    tryCatch({
      # Lire le fichier
      df <- NULL
      
      # Essayer d'abord comme CSV/texte (les fichiers TEMPO sont en texte)
      tryCatch({
        df <- read_delim(fichier, delim = "\t", locale = locale(encoding = "UTF-8"), show_col_types = FALSE)
      }, error = function(e1) {
        tryCatch({
          df <- read_delim(fichier, delim = ";", locale = locale(encoding = "UTF-8"), show_col_types = FALSE)
        }, error = function(e2) {
          tryCatch({
            df <- read_excel(fichier, sheet = 1)
          }, error = function(e3) {
            # Ignorer l'erreur, df reste NULL
          })
        })
      })
      
      if (is.null(df) || nrow(df) == 0) {
        cat("      ⚠️ Impossible de lire le fichier ou fichier vide\n")
        next
      }
      
      # Extraire la saison du nom de fichier
      saison <- str_extract(basename(fichier), "\\d{4}-\\d{4}")
      if (is.na(saison)) {
        saison <- tools::file_path_sans_ext(basename(fichier))
      }
      
      # Ajouter colonne saison
      df$Saison_TEMPO <- saison
      
      # Essayer de trouver les colonnes Date et Couleur
      colnames_lower <- tolower(colnames(df))
      
      # Chercher colonne date
      idx_date <- which(grepl("date|jour", colnames_lower))[1]
      if (is.na(idx_date) && "Date" %in% colnames(df)) {
        idx_date <- which(colnames(df) == "Date")[1]
      }
      if (is.na(idx_date)) {
        # Prendre la première colonne
        idx_date <- 1
      }
      
      # Chercher colonne couleur (chercher dans les noms ET dans les valeurs)
      idx_couleur <- which(grepl("couleur|tempo|rouge|bleu|blanc|type.*jour|jour.*tempo", colnames_lower))[1]
      if (is.na(idx_couleur) && "Couleur_TEMPO" %in% colnames(df)) {
        idx_couleur <- which(colnames(df) == "Couleur_TEMPO")[1]
      }
      # Si toujours pas trouvé, chercher dans les valeurs de la 2e colonne
      if (is.na(idx_couleur) && ncol(df) >= 2) {
        # Vérifier si la 2e colonne contient des valeurs BLEU/ROUGE/BLANC
        valeurs_col2 <- unique(toupper(as.character(df[[2]])))
        if (any(grepl("BLEU|ROUGE|BLANC|R|B|W", valeurs_col2))) {
          idx_couleur <- 2
        }
      }
      # Si toujours pas trouvé, prendre la 2e colonne par défaut
      if (is.na(idx_couleur) && ncol(df) >= 2) {
        idx_couleur <- 2
      }
      
      # Standardiser les noms
      if (idx_date <= ncol(df)) {
        colnames(df)[idx_date] <- "Date"
      }
      if (!is.na(idx_couleur) && idx_couleur <= ncol(df)) {
        colnames(df)[idx_couleur] <- "Couleur_TEMPO"
      }
      
      # Convertir Date en format date
      if ("Date" %in% colnames(df)) {
        # Essayer différents formats de date
        df$Date <- tryCatch({
          as.Date(df$Date)
        }, error = function(e) {
          tryCatch({
            as.Date(df$Date, format = "%d/%m/%Y")
          }, error = function(e2) {
            tryCatch({
              as.Date(df$Date, format = "%Y-%m-%d")
            }, error = function(e3) {
              # Dernier essai : parser manuellement
              as.Date(str_extract(df$Date, "\\d{4}-\\d{2}-\\d{2}"))
            })
          })
        })
      }
      
      # Standardiser les couleurs (R/B/W ou Rouge/Blanc/Bleu)
      if ("Couleur_TEMPO" %in% colnames(df)) {
        couleur_raw <- toupper(trimws(as.character(df$Couleur_TEMPO)))
        # Remplacer les valeurs directement - BLEU doit matcher
        df$Couleur_TEMPO <- ifelse(
          grepl("ROUGE|^R$", couleur_raw), "Rouge",
          ifelse(
            grepl("BLEU|^B$", couleur_raw), "Bleu",
            ifelse(
              grepl("BLANC|^W$", couleur_raw), "Blanc",
              NA_character_
            )
          )
        )
      }
      
      # Filtrer les lignes valides (avec Date et Couleur)
      if ("Date" %in% colnames(df) && "Couleur_TEMPO" %in% colnames(df)) {
        # Compter avant filtrage
        n_avant <- nrow(df)
        
        # Filtrer
        df <- df %>%
          filter(!is.na(Date)) %>%
          filter(!is.na(Couleur_TEMPO)) %>%
          filter(Couleur_TEMPO %in% c("Rouge", "Bleu", "Blanc")) %>%
          select(Date, Couleur_TEMPO, Saison_TEMPO) %>%
          distinct(Date, .keep_all = TRUE)  # Éviter doublons
        
        # Si toutes les lignes ont été filtrées, il y a un problème
        if (nrow(df) == 0 && n_avant > 0) {
          cat("      ⚠️ Toutes les lignes filtrées (", n_avant, "-> 0)\n")
          cat("      💡 Vérifier format Date et Couleur\n")
        }
      }
      
      if (nrow(df) > 0) {
        liste_dfs[[basename(fichier)]] <- df
        cat("      ✅", nrow(df), "lignes\n")
      } else {
        cat("      ⚠️ Aucune ligne valide après traitement\n")
      }
      
    }, error = function(e) {
      cat("      ❌ Erreur:", e$message, "\n")
    })
  }
  
  if (length(liste_dfs) == 0) {
    cat("   ❌ Aucun fichier n'a pu être lu\n\n")
    return(NULL)
  }
  
  # Combiner tous les fichiers
  cat("\n   🔗 Combinaison des calendriers TEMPO...\n")
  
  # Trouver colonnes communes
  colonnes_communes <- Reduce(intersect, lapply(liste_dfs, colnames))
  
  # Si Date et Couleur_TEMPO sont présentes, les garder
  colonnes_importantes <- c("Date", "Couleur_TEMPO", "Saison_TEMPO")
  colonnes_importantes <- colonnes_importantes[colonnes_importantes %in% colonnes_communes]
  
  if (length(colonnes_importantes) > 0) {
    df_combine <- bind_rows(lapply(liste_dfs, function(df) {
      df[, colonnes_importantes, drop = FALSE]
    })) %>%
      distinct(Date, .keep_all = TRUE) %>%  # Éviter doublons
      arrange(Date)
    
    cat("   ✅", nrow(df_combine), "jours TEMPO combinés\n")
    cat("   📊 Répartition:\n")
    if ("Couleur_TEMPO" %in% colnames(df_combine)) {
      repartition <- table(df_combine$Couleur_TEMPO, useNA = "ifany")
      for (i in 1:length(repartition)) {
        cat("      -", names(repartition)[i], ":", repartition[i], "jours\n")
      }
    }
    cat("\n")
    
    return(df_combine)
  } else {
    cat("   ⚠️ Colonnes Date ou Couleur_TEMPO non trouvées\n\n")
    return(NULL)
  }
}

# =============================================================================
# FONCTION : CRÉER CALENDRIER COMPLET
# =============================================================================

creer_calendrier_complet <- function(annee_debut = 2012, annee_fin = 2025) {
  cat(paste0(rep("=", 80), collapse = ""), "\n")
  cat("📅 CRÉATION DU CALENDRIER FRANÇAIS COMPLET\n")
  cat(paste0(rep("=", 80), collapse = ""), "\n\n")
  
  # 1. Créer calendrier de base avec jours fériés
  cat("1️⃣ Création du calendrier de base...\n")
  calendrier <- creer_jours_feries(annee_debut, annee_fin)
  
  # 2. Ajouter variables temporelles supplémentaires
  cat("2️⃣ Ajout de variables temporelles...\n")
  calendrier <- calendrier %>%
    mutate(
      # Saison météorologique
      Saison = case_when(
        Mois %in% c(12, 1, 2) ~ "Hiver",
        Mois %in% c(3, 4, 5) ~ "Printemps",
        Mois %in% c(6, 7, 8) ~ "Été",
        Mois %in% c(9, 10, 11) ~ "Automne"
      ),
      
      # Trimestre
      Trimestre = quarter(Date),
      
      # Semaine de l'année
      SemaineAnnee = week(Date),
      
      # Jour de l'année
      JourAnnee = yday(Date),
      
      # Est jour ouvrable (lundi-vendredi, non férié)
      EstOuvrable = !EstWeekend & !EstFerie,
      
      # Est pont (vendredi ou lundi autour d'un week-end avec férié)
      EstPont = FALSE  # À calculer après
    )
  
  # Calculer les ponts (jours entre férié et week-end)
  calendrier <- calendrier %>%
    mutate(
      EstPont = (
        (EstFerie & lead(EstWeekend, 1) == TRUE) |
        (EstFerie & lag(EstWeekend, 1) == TRUE) |
        (EstWeekend & lead(EstFerie, 1) == TRUE) |
        (EstWeekend & lag(EstFerie, 1) == TRUE)
      ) & !EstFerie & !EstWeekend
    )
  
  cat("   ✅ Variables temporelles ajoutées\n\n")
  
  # 3. Ajouter calendrier TEMPO
  cat("3️⃣ Ajout du calendrier TEMPO...\n")
  tempo <- lire_calendrier_tempo()
  
  if (!is.null(tempo) && "Date" %in% colnames(tempo)) {
    calendrier <- calendrier %>%
      left_join(
        tempo %>% select(Date, Couleur_TEMPO, Saison_TEMPO),
        by = "Date"
      ) %>%
      mutate(
        EstTEMPO_Rouge = Couleur_TEMPO == "Rouge",
        EstTEMPO_Blanc = Couleur_TEMPO == "Blanc",
        EstTEMPO_Bleu = Couleur_TEMPO == "Bleu"
      )
    
    cat("   ✅ Calendrier TEMPO intégré\n")
    cat("   📊 Jours TEMPO:", sum(!is.na(calendrier$Couleur_TEMPO)), "\n\n")
  } else {
    calendrier$Couleur_TEMPO <- NA
    calendrier$Saison_TEMPO <- NA
    calendrier$EstTEMPO_Rouge <- FALSE
    calendrier$EstTEMPO_Blanc <- FALSE
    calendrier$EstTEMPO_Bleu <- FALSE
    cat("   ⚠️ Calendrier TEMPO non disponible\n\n")
  }
  
  # 4. Ajouter variables d'analyse
  cat("4️⃣ Ajout de variables d'analyse...\n")
  calendrier <- calendrier %>%
    mutate(
      # Impact attendu sur consommation (score 0-10)
      ImpactConsommation = case_when(
        EstTEMPO_Rouge ~ 10,  # Très haute consommation
        EstTEMPO_Blanc ~ 7,   # Haute consommation
        EstTEMPO_Bleu ~ 3,    # Basse consommation
        EstFerie ~ 2,         # Jours fériés = faible consommation
        EstWeekend ~ 4,       # Week-end = consommation modérée
        EstOuvrable ~ 6,     # Jour ouvrable normal
        TRUE ~ 5
      ),
      
      # Type de jour
      TypeJour = case_when(
        EstFerie ~ "Férié",
        EstWeekend ~ "Week-end",
        EstTEMPO_Rouge ~ "TEMPO Rouge",
        EstTEMPO_Blanc ~ "TEMPO Blanc",
        EstTEMPO_Bleu ~ "TEMPO Bleu",
        EstOuvrable ~ "Ouvrable",
        TRUE ~ "Autre"
      )
    )
  
  cat("   ✅ Variables d'analyse ajoutées\n\n")
  
  # 5. Sauvegarder
  cat("5️⃣ Sauvegarde du calendrier...\n")
  write.csv(calendrier, 
            file.path(OUTPUT_DIR, "calendrier_francais_complet.csv"),
            row.names = FALSE)
  
  cat("   ✅ Calendrier sauvegardé:", 
      file.path(OUTPUT_DIR, "calendrier_francais_complet.csv"), "\n\n")
  
  # Résumé
  cat("📊 RÉSUMÉ DU CALENDRIER:\n")
  cat("   - Période:", min(calendrier$Date), "à", max(calendrier$Date), "\n")
  cat("   - Total jours:", nrow(calendrier), "\n")
  cat("   - Jours fériés:", sum(calendrier$EstFerie), "\n")
  cat("   - Week-ends:", sum(calendrier$EstWeekend), "\n")
  cat("   - Jours ouvrables:", sum(calendrier$EstOuvrable), "\n")
  if (!is.null(tempo)) {
    cat("   - Jours TEMPO Rouge:", sum(calendrier$EstTEMPO_Rouge, na.rm = TRUE), "\n")
    cat("   - Jours TEMPO Blanc:", sum(calendrier$EstTEMPO_Blanc, na.rm = TRUE), "\n")
    cat("   - Jours TEMPO Bleu:", sum(calendrier$EstTEMPO_Bleu, na.rm = TRUE), "\n")
  }
  cat("\n")
  
  return(calendrier)
}

# =============================================================================
# FONCTION : FUSIONNER CALENDRIER AVEC DONNÉES ÉNERGÉTIQUES
# =============================================================================

fusionner_avec_donnees <- function(calendrier, donnees_energie) {
  cat("🔗 Fusion du calendrier avec les données énergétiques...\n")
  
  # Vérifier que les données ont une colonne Date
  if (!"Date" %in% colnames(donnees_energie)) {
    cat("   ⚠️ Colonne 'Date' non trouvée dans les données\n")
    cat("   💡 Les données doivent avoir une colonne 'Date' au format Date\n")
    return(NULL)
  }
  
  # Convertir Date en format date si nécessaire
  if (!inherits(donnees_energie$Date, "Date")) {
    donnees_energie$Date <- as.Date(donnees_energie$Date)
  }
  
  # Fusionner
  donnees_fusionnees <- donnees_energie %>%
    left_join(calendrier, by = "Date")
  
  cat("   ✅ Fusion réussie:", nrow(donnees_fusionnees), "lignes\n")
  cat("   📊 Colonnes ajoutées:", 
      length(colnames(donnees_fusionnees)) - length(colnames(donnees_energie)), "\n\n")
  
  return(donnees_fusionnees)
}

# =============================================================================
# EXÉCUTION
# =============================================================================

# Exécuter si script lancé directement
if (!interactive()) {
  # Changer vers le bon répertoire
  projet_dir <- "/Volumes/YAHYA SSD/Documents/Serie temp/PROJET_ENERGIE_FRANCE/R_VERSION"
  if (dir.exists(projet_dir)) {
    setwd(projet_dir)
  }
  
  # Créer le calendrier complet
  calendrier_complet <- creer_calendrier_complet(2012, 2025)
}

