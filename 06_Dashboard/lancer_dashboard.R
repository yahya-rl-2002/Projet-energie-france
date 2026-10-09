if (!requireNamespace("shiny", quietly = TRUE)) stop("Installer shiny : install.packages('shiny')")
chemin <- if (file.exists("06_Dashboard/app.R")) "06_Dashboard" else "."
shiny::runApp(chemin, launch.browser = interactive())
