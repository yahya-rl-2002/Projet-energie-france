# Point d'entrée conservé : calcul centralisé dans le pipeline horaire corrigé.
# Les anciens algorithmes et résultats sont archivés, voir README.md.
.racines <- c(".", "..")
.racine <- .racines[file.exists(file.path(.racines, "config_horaire.json"))][1]
if (is.na(.racine)) stop("Lancer depuis la racine du dépôt ou le dossier du script.")
source(file.path(.racine, "EXECUTER_TOUT.R"))
executer_pipeline_horaire(.racine)
