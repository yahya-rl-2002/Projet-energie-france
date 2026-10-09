# Tests de lecture des résultats versionnés et des filtres du dashboard.
if (!requireNamespace("shiny", quietly = TRUE)) stop("Installer shiny pour tester le dashboard.")
e <- new.env(parent = globalenv())
sys.source("06_Dashboard/app.R", envir = e)
stopifnot(!anyNA(e$previsions$Date), length(unique(e$previsions$Modele)) == 1)
shiny::testServer(e$server, {
  session$setInputs(phase = "test", horizon = "24")
  stopifnot(nrow(scores()) == 5, all(scores()$Phase == "test"), all(scores()$Horizon == 24))
  session$setInputs(phase = "validation", horizon = "168")
  stopifnot(nrow(scores()) == 5, all(scores()$Phase == "validation"), all(scores()$Horizon == 168))
})
message("Tests dashboard : OK")
