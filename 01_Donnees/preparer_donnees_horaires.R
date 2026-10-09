charger_source_horaire <- function(racine = ".") {
  paths <- file.path(racine, "data/RTE", c("RTE_annuels_combines.csv", "RTE_en_cours_combines.csv"))
  paths <- paths[file.exists(paths)]
  if (length(paths)) {
    raw <- data.table::rbindlist(lapply(paths, function(p)
      data.table::fread(p, select = c("Date", "Heures", "Consommation"),
                       colClasses = list(character = c("Date", "Heures")))))
    type <- "RTE_brut"
  } else {
    paths <- file.path(racine, "data/dataset_complet.csv")
    if (!file.exists(paths)) stop("Données absentes : placer les exports RTE dans data/RTE/ ou fournir data/dataset_complet.csv.")
    raw <- data.table::fread(paths, select = c("Date", "Consommation"),
                            colClasses = list(character = "Date"))
    type <- "ancien_dataset_consommation_seule"
  }
  list(brut = raw, sources = data.frame(fichier = basename(paths),
    md5 = unname(tools::md5sum(paths))), type = type)
}

executer_preparation_horaire <- function(racine = ".") {
  source <- charger_source_horaire(racine)
  res <- preparer_horaire(source$brut)
  res$qualite$type_source <- source$type
  res$qualite$sources <- source$sources
  out <- file.path(racine, "data/dataset_horaire.csv")
  export <- data.table::copy(res$donnees)
  export[, Date := format(Date, tz = "UTC", format = "%Y-%m-%dT%H:%M:%SZ")]
  data.table::fwrite(export, out, na = "NA")
  message("Dataset horaire : ", nrow(export), " heures ; ",
          res$qualite$heures_manquantes_ou_incompletes, " heures manquantes/incomplètes.")
  res
}
