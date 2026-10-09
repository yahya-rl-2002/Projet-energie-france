# Remplace les jointures multiples par une préparation horaire de la consommation.
# Les métadonnées externes ne sont pas utilisées par les modèles univariés actuels.
combiner_toutes_donnees <- function(racine = NULL) {
  if (is.null(racine)) {
    candidats <- c(".", "..")
    racine <- candidats[file.exists(file.path(candidats, "config_horaire.json"))][1]
  }
  if (is.na(racine)) stop("Lancer depuis la racine du dépôt ou 01_Donnees/.")
  source(file.path(racine, "00_Utilitaires/series_horaires.R"), local = TRUE)
  source(file.path(racine, "01_Donnees/preparer_donnees_horaires.R"), local = TRUE)
  executer_preparation_horaire(racine)$donnees
}
if (sys.nframe() == 0L) dataset <- combiner_toutes_donnees()
