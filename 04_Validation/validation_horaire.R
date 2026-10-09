evaluer_origines <- function(df, origines, modeles, train_heures = 56L * 24L,
                            horizons = c(1L, 24L, 168L), phase = "validation") {
  predictions <- list(); exclus <- list(); details <- list()
  for (j in seq_along(origines)) {
    origine <- origines[j]
    message(phase, " ", j, "/", length(origines), " : ", format(origine, tz = "UTC"))
    w <- tryCatch(fenetre_origine(df, origine, train_heures, max(horizons)), error = identity)
    if (inherits(w, "error")) {
      exclus[[length(exclus) + 1L]] <- data.frame(Phase = phase,
        Origine = format(origine, tz = "UTC", usetz = TRUE), Raison = conditionMessage(w))
      next
    }
    for (m in modeles) {
      # Un échec de modèle arrête le calcul ; pas de classement sur des dates différentes.
      f <- prevoir_modele(w$train, m, max(horizons))
      if (length(f$mean) != max(horizons) || any(!is.finite(f$mean))) stop("Prévisions invalides : ", m)
      echelle <- mean(abs(diff(w$train, lag = 24)))
      predictions[[length(predictions) + 1L]] <- data.table::data.table(
        Phase = phase, Origine = origine, Date = w$dates, Modele = m,
        Pas = seq_along(w$test), Observation = w$test, Prediction = f$mean,
        Echelle_MASE = echelle, N_imputees_train = w$n_imputees,
        Lower80 = if (is.null(f$lower)) NA_real_ else as.numeric(f$lower[, 1]),
        Upper80 = if (is.null(f$upper)) NA_real_ else as.numeric(f$upper[, 1]),
        Lower95 = if (is.null(f$lower)) NA_real_ else as.numeric(f$lower[, 2]),
        Upper95 = if (is.null(f$upper)) NA_real_ else as.numeric(f$upper[, 2]))
      for (h in horizons) {
        met <- metriques_horaires(w$test[seq_len(h)], f$mean[seq_len(h)], w$train)
        details[[length(details) + 1L]] <- cbind(data.frame(Phase = phase,
          Origine = origine, Modele = m, Horizon = h), met)
      }
    }
  }
  if (!length(predictions)) stop("Aucune origine exploitable.")
  p <- data.table::rbindlist(predictions)
  agreges <- data.table::rbindlist(lapply(horizons, function(h) {
    p[Pas <= h, {
      err <- Observation - Prediction
      sst <- sum((Observation - mean(Observation))^2)
      .(Horizon = h, N_origines = data.table::uniqueN(Origine), N = .N,
        RMSE = sqrt(mean(err^2)), MAE = mean(abs(err)),
        MAPE = 100 * mean(abs(err / Observation)),
        R_squared = if (sst > 0 && .N > 1) 1 - sum(err^2) / sst else NA_real_,
        MASE = if (all(Echelle_MASE > 0)) mean(abs(err) / Echelle_MASE) else NA_real_,
        Couverture80 = if (all(is.finite(Lower80))) 100 * mean(Observation >= Lower80 & Observation <= Upper80) else NA_real_,
        Couverture95 = if (all(is.finite(Lower95))) 100 * mean(Observation >= Lower95 & Observation <= Upper95) else NA_real_,
        Largeur95 = if (all(is.finite(Lower95))) mean(Upper95 - Lower95) else NA_real_)
    }, by = .(Phase, Modele)]
  }))
  list(predictions = p, metriques = agreges,
       details = data.table::rbindlist(details),
       exclusions = if (length(exclus)) data.table::rbindlist(exclus) else
         data.table::data.table(Phase = character(), Origine = character(), Raison = character()))
}

origines_mensuelles <- function(annee, derniere_date, h = 168L) {
  # Origine = fin de la dernière heure du mois précédent ; début du test le 1er à 00 h UTC.
  debut <- as.POSIXct(sprintf("%d-%02d-01 00:00:00", annee, 1:12), tz = "UTC")
  origines <- debut - 3600
  origines[origines + h * 3600 <= derniere_date]
}

executer_validation_horaire <- function(df, config) {
  modeles <- unlist(config$modeles)
  horizons <- as.integer(unlist(config$horizons))
  val_o <- origines_mensuelles(config$annee_validation, max(df$Date), max(horizons))
  test_o <- origines_mensuelles(config$annee_test, max(df$Date), max(horizons))
  if (config$annee_test <= config$annee_validation) stop("Test antérieur à la validation.")
  validation <- evaluer_origines(df, val_o, modeles, config$train_heures, horizons, "validation")
  rang <- validation$metriques[Horizon == config$horizon_selection]
  data.table::setorder(rang, RMSE, Modele)
  selection <- rang$Modele[1]
  message("Modèle figé sur la validation : ", selection)
  # Réentraînement autorisé à chaque origine avec son passé, sans sélection sur le test.
  test <- evaluer_origines(df, test_o, modeles, config$train_heures, horizons, "test")
  list(validation = validation, test = test, selection = selection)
}
