library(shiny)

racines <- c(".", "..")
racine <- racines[file.exists(file.path(racines, "config_horaire.json"))][1]
if (is.na(racine)) stop("Lancer depuis la racine du dépôt ou 06_Dashboard/.")
rep_resultats <- file.path(racine, "docs/resultats_corriges")
lire_resultat <- function(nom) {
  p <- file.path(rep_resultats, nom)
  if (!file.exists(p)) stop("Résultats absents : exécuter Rscript EXECUTER_TOUT.R.")
  read.csv(p, stringsAsFactors = FALSE)
}
validation <- lire_resultat("metriques_validation.csv")
test <- lire_resultat("metriques_test.csv")
previsions <- lire_resultat("previsions_168h.csv")
previsions$Date <- as.POSIXct(previsions$Date, format = "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
protocole <- jsonlite::read_json(file.path(rep_resultats, "protocole.json"), simplifyVector = TRUE)

ui <- fluidPage(
  titlePanel("Consommation électrique — résultats horaires corrigés"),
  p(paste("Modèle choisi sur la validation :", protocole$selection_validation)),
  p("Validation 2024 et test 2025 : une origine par mois, mêmes dates pour tous les modèles."),
  sidebarLayout(
    sidebarPanel(
      selectInput("phase", "Période", c("Test final" = "test", "Validation" = "validation")),
      selectInput("horizon", "Fenêtre prévue (heures)", c(1, 24, 168), selected = 24),
      p("Chaque score regroupe les erreurs des pas 1 à H. Les horodatages sont en UTC."),
      downloadButton("telecharger", "Télécharger les métriques")
    ),
    mainPanel(
      h3("Comparaison des modèles"), plotOutput("comparaison"), tableOutput("metriques"),
      h3("Prévisions après la dernière observation"),
      p(paste("Origine :", protocole$date_origine_previsions_utc,
              "— ces données historiques ne constituent pas une prévision pour aujourd'hui.")),
      plotOutput("previsions"),
      p("Les trous des cibles sont exclus, les petits trous d'entraînement sont remplis à partir du passé. Les données sont un instantané historique révisable. Voir le rapport pour les limites et la couverture des intervalles.")
    )
  )
)
server <- function(input, output, session) {
  scores <- reactive({
    d <- if (input$phase == "test") test else validation
    d[d$Horizon == as.integer(input$horizon), ]
  })
  output$metriques <- renderTable(scores()[, c("Modele", "N_origines", "RMSE", "MAE", "MAPE", "R_squared", "MASE")], digits = 3)
  output$comparaison <- renderPlot({
    s <- scores()
    barplot(s$RMSE, names.arg = s$Modele, col = "#24679c", ylab = "RMSE (MW)", las = 2)
  })
  output$previsions <- renderPlot({
    plot(previsions$Date, previsions$Prediction_MW, type = "l", col = "#24679c",
         xlab = "Date UTC", ylab = "Consommation prévue (MW)")
  })
  output$telecharger <- downloadHandler(
    filename = function() paste0("metriques_", input$phase, "_", input$horizon, "h.csv"),
    content = function(file) write.csv(scores(), file, row.names = FALSE))
}
shinyApp(ui, server)
