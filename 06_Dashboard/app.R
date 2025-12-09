# =============================================================================
# DASHBOARD INTERACTIF - PRÉVISION DE CONSOMMATION ÉLECTRIQUE
# =============================================================================
# Application Shiny pour visualiser les données et les prévisions

library(shiny)
library(shinydashboard)
library(plotly)
library(DT)
library(tidyverse)
library(forecast)
library(lubridate)

# Configurer miroir CRAN
options(repos = c(CRAN = "https://cran.rstudio.com/"))

# =============================================================================
# CHARGER LES DONNÉES
# =============================================================================

charger_donnees <- function() {
  # Chemins possibles
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
    return(NULL)
  }
  
  df <- read.csv(chemin_dataset, stringsAsFactors = FALSE)
  df$Date <- as.POSIXct(df$Date)
  df <- df %>%
    filter(!is.na(Consommation), !is.na(Date)) %>%
    arrange(Date)
  
  return(df)
}

# Charger les données au démarrage
donnees <- charger_donnees()

# Charger les prévisions si disponibles
charger_previsions <- function() {
  chemins_previsions <- c(
    "data/previsions_multi_horizons.csv",
    "../data/previsions_multi_horizons.csv"
  )
  
  for (chemin in chemins_previsions) {
    if (file.exists(chemin)) {
      return(read.csv(chemin))
    }
  }
  return(NULL)
}

previsions <- charger_previsions()

# Charger les scénarios si disponibles
charger_scenarios <- function() {
  chemins_scenarios <- c(
    "data/previsions_scenarios.csv",
    "../data/previsions_scenarios.csv"
  )
  
  for (chemin in chemins_scenarios) {
    if (file.exists(chemin)) {
      return(read.csv(chemin))
    }
  }
  return(NULL)
}

scenarios <- charger_scenarios()

# =============================================================================
# INTERFACE UTILISATEUR
# =============================================================================

ui <- dashboardPage(
  dashboardHeader(title = "📊 Dashboard Énergie France"),
  
  dashboardSidebar(
    sidebarMenu(
      menuItem("📈 Vue d'ensemble", tabName = "overview", icon = icon("dashboard")),
      menuItem("🔮 Prévisions", tabName = "forecasts", icon = icon("chart-line")),
      menuItem("📊 Scénarios", tabName = "scenarios", icon = icon("project-diagram")),
      menuItem("📉 Analyse", tabName = "analysis", icon = icon("chart-bar")),
      menuItem("ℹ️ À propos", tabName = "about", icon = icon("info-circle"))
    ),
    
    # Paramètres
    br(),
    h4("⚙️ Paramètres", style = "padding-left: 15px;"),
    
    # Sélection de la période
    dateRangeInput(
      "date_range",
      "Période",
      start = if (!is.null(donnees)) min(donnees$Date) else Sys.Date() - 30,
      end = if (!is.null(donnees)) max(donnees$Date) else Sys.Date(),
      min = if (!is.null(donnees)) min(donnees$Date) else Sys.Date() - 365,
      max = if (!is.null(donnees)) max(donnees$Date) else Sys.Date()
    ),
    
    # Horizon de prévision
    sliderInput(
      "horizon",
      "Horizon de prévision (heures)",
      min = 1,
      max = 168,
      value = 24,
      step = 1
    ),
    
    # Modèle
    selectInput(
      "modele",
      "Modèle",
      choices = c("TBATS", "ARIMA", "ETS"),
      selected = "TBATS"
    )
  ),
  
  dashboardBody(
    tags$head(
      tags$style(HTML("
        .content-wrapper, .right-side {
          background-color: #f4f4f4;
        }
      "))
    ),
    
    tabItems(
      # =======================================================================
      # VUE D'ENSEMBLE
      # =======================================================================
      tabItem(
        tabName = "overview",
        h2("📈 Vue d'ensemble"),
        
        fluidRow(
          valueBox(
            value = if (!is.null(donnees)) format(round(mean(donnees$Consommation, na.rm = TRUE)), big.mark = " "),
            subtitle = "Consommation moyenne (MW)",
            icon = icon("bolt"),
            color = "yellow",
            width = 4
          ),
          valueBox(
            value = if (!is.null(donnees)) format(nrow(donnees), big.mark = " "),
            subtitle = "Observations",
            icon = icon("database"),
            color = "blue",
            width = 4
          ),
          valueBox(
            value = if (!is.null(donnees)) {
              paste(
                format(min(donnees$Date), "%d/%m/%Y"),
                "-",
                format(max(donnees$Date), "%d/%m/%Y")
              )
            } else {
              "N/A"
            },
            subtitle = "Période",
            icon = icon("calendar"),
            color = "green",
            width = 4
          )
        ),
        
        fluidRow(
          box(
            title = "Consommation Électrique - Vue Temporelle",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("plot_overview", height = "500px")
          )
        ),
        
        fluidRow(
          box(
            title = "Statistiques Descriptives",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            DT::dataTableOutput("stats_table")
          )
        )
      ),
      
      # =======================================================================
      # PRÉVISIONS
      # =======================================================================
      tabItem(
        tabName = "forecasts",
        h2("🔮 Prévisions"),
        
        fluidRow(
          box(
            title = "Prévisions Multi-Horizons",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("plot_forecasts", height = "600px")
          )
        ),
        
        fluidRow(
          box(
            title = "Détails des Prévisions",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            DT::dataTableOutput("forecasts_table")
          )
        )
      ),
      
      # =======================================================================
      # SCÉNARIOS
      # =======================================================================
      tabItem(
        tabName = "scenarios",
        h2("📊 Scénarios"),
        
        fluidRow(
          box(
            title = "Comparaison des Scénarios",
            status = "primary",
            solidHeader = TRUE,
            width = 12,
            plotlyOutput("plot_scenarios", height = "600px")
          )
        ),
        
        fluidRow(
          box(
            title = "Statistiques par Scénario",
            status = "info",
            solidHeader = TRUE,
            width = 12,
            DT::dataTableOutput("scenarios_table")
          )
        )
      ),
      
      # =======================================================================
      # ANALYSE
      # =======================================================================
      tabItem(
        tabName = "analysis",
        h2("📉 Analyse"),
        
        fluidRow(
          box(
            title = "Distribution de la Consommation",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("plot_distribution", height = "400px")
          ),
          box(
            title = "Consommation par Heure",
            status = "primary",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("plot_hourly", height = "400px")
          )
        ),
        
        fluidRow(
          box(
            title = "Consommation par Jour de la Semaine",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("plot_weekly", height = "400px")
          ),
          box(
            title = "Consommation par Mois",
            status = "info",
            solidHeader = TRUE,
            width = 6,
            plotlyOutput("plot_monthly", height = "400px")
          )
        )
      ),
      
      # =======================================================================
      # À PROPOS
      # =======================================================================
      tabItem(
        tabName = "about",
        h2("ℹ️ À propos"),
        
        box(
          title = "Informations sur le Dashboard",
          status = "info",
          solidHeader = TRUE,
          width = 12,
          h3("Dashboard de Prévision de Consommation Électrique"),
          p("Cette application permet de visualiser et analyser les données de consommation électrique en France."),
          
          h4("Fonctionnalités :"),
          tags$ul(
            tags$li("Visualisation interactive des données historiques"),
            tags$li("Prévisions multi-horizons avec intervalles de confiance"),
            tags$li("Comparaison de scénarios (optimiste, réaliste, pessimiste)"),
            tags$li("Analyses statistiques et temporelles"),
            tags$li("Sélection de modèles (TBATS, ARIMA, ETS)")
          ),
          
          h4("Modèles disponibles :"),
          tags$ul(
            tags$li("TBATS : Modèle adaptatif avec saisonnalité complexe"),
            tags$li("ARIMA : Modèle autorégressif intégré"),
            tags$li("ETS : Modèle de lissage exponentiel")
          ),
          
          br(),
          p("Développé avec R Shiny pour le projet d'analyse de séries temporelles.")
        )
      )
    )
  )
)

# =============================================================================
# SERVEUR
# =============================================================================

server <- function(input, output, session) {
  
  # Filtrer les données selon la période sélectionnée
  donnees_filtrees <- reactive({
    if (is.null(donnees)) return(NULL)
    
    donnees %>%
      filter(Date >= input$date_range[1] & Date <= input$date_range[2])
  })
  
  # =========================================================================
  # VUE D'ENSEMBLE
  # =========================================================================
  
  output$plot_overview <- renderPlotly({
    if (is.null(donnees_filtrees())) {
      return(plotly_empty())
    }
    
    df <- donnees_filtrees()
    
    p <- plot_ly(
      df,
      x = ~Date,
      y = ~Consommation,
      type = "scatter",
      mode = "lines",
      name = "Consommation",
      line = list(color = "steelblue", width = 1)
    ) %>%
      layout(
        title = "Évolution de la Consommation Électrique",
        xaxis = list(title = "Date"),
        yaxis = list(title = "Consommation (MW)"),
        hovermode = "x unified"
      )
    
    return(p)
  })
  
  output$stats_table <- DT::renderDataTable({
    if (is.null(donnees_filtrees())) {
      return(data.frame())
    }
    
    df <- donnees_filtrees()
    
    stats <- data.frame(
      Statistique = c(
        "Moyenne", "Médiane", "Écart-type", "Minimum", "Maximum",
        "1er Quartile", "3ème Quartile"
      ),
      Valeur = c(
        round(mean(df$Consommation, na.rm = TRUE), 2),
        round(median(df$Consommation, na.rm = TRUE), 2),
        round(sd(df$Consommation, na.rm = TRUE), 2),
        round(min(df$Consommation, na.rm = TRUE), 2),
        round(max(df$Consommation, na.rm = TRUE), 2),
        round(quantile(df$Consommation, 0.25, na.rm = TRUE), 2),
        round(quantile(df$Consommation, 0.75, na.rm = TRUE), 2)
      )
    )
    
    DT::datatable(stats, options = list(pageLength = 10))
  })
  
  # =========================================================================
  # PRÉVISIONS
  # =========================================================================
  
  output$plot_forecasts <- renderPlotly({
    if (is.null(previsions)) {
      return(plotly_empty() %>% 
        add_annotations(
          text = "Aucune prévision disponible. Exécutez d'abord les scripts de prévision.",
          x = 0.5, y = 0.5,
          xref = "paper", yref = "paper",
          showarrow = FALSE
        ))
    }
    
    # Filtrer par horizon
    prev_filtrees <- previsions %>%
      filter(Horizon == input$horizon)
    
    if (nrow(prev_filtrees) == 0) {
      return(plotly_empty())
    }
    
    p <- plot_ly(
      prev_filtrees,
      x = ~Pas,
      y = ~Prevision,
      type = "scatter",
      mode = "lines",
      name = "Prévision",
      line = list(color = "blue", width = 2)
    ) %>%
      add_ribbons(
        ymin = ~Lower_95,
        ymax = ~Upper_95,
        name = "Intervalle 95%",
        fillcolor = "rgba(0,100,255,0.2)",
        line = list(color = "transparent")
      ) %>%
      add_ribbons(
        ymin = ~Lower_80,
        ymax = ~Upper_80,
        name = "Intervalle 80%",
        fillcolor = "rgba(0,100,255,0.3)",
        line = list(color = "transparent")
      ) %>%
      layout(
        title = paste("Prévisions - Horizon", input$horizon, "heures"),
        xaxis = list(title = "Pas de temps"),
        yaxis = list(title = "Consommation (MW)"),
        hovermode = "x unified"
      )
    
    return(p)
  })
  
  output$forecasts_table <- DT::renderDataTable({
    if (is.null(previsions)) {
      return(data.frame())
    }
    
    prev_filtrees <- previsions %>%
      filter(Horizon == input$horizon) %>%
      select(Horizon, Pas, Prevision, Lower_80, Upper_80, Lower_95, Upper_95)
    
    DT::datatable(prev_filtrees, options = list(pageLength = 20))
  })
  
  # =========================================================================
  # SCÉNARIOS
  # =========================================================================
  
  output$plot_scenarios <- renderPlotly({
    if (is.null(scenarios)) {
      return(plotly_empty() %>% 
        add_annotations(
          text = "Aucun scénario disponible. Exécutez d'abord le script d'analyse de scénarios.",
          x = 0.5, y = 0.5,
          xref = "paper", yref = "paper",
          showarrow = FALSE
        ))
    }
    
    p <- plot_ly(
      scenarios,
      x = ~Horizon,
      y = ~Prevision,
      color = ~Scenario,
      type = "scatter",
      mode = "lines",
      line = list(width = 2)
    ) %>%
      layout(
        title = "Comparaison des Scénarios",
        xaxis = list(title = "Horizon (heures)"),
        yaxis = list(title = "Consommation (MW)"),
        hovermode = "x unified"
      )
    
    return(p)
  })
  
  output$scenarios_table <- DT::renderDataTable({
    if (is.null(scenarios)) {
      return(data.frame())
    }
    
    stats_scenarios <- scenarios %>%
      group_by(Scenario) %>%
      summarise(
        Moyenne = round(mean(Prevision, na.rm = TRUE), 2),
        Min = round(min(Prevision, na.rm = TRUE), 2),
        Max = round(max(Prevision, na.rm = TRUE), 2),
        Ecart_type = round(sd(Prevision, na.rm = TRUE), 2),
        .groups = "drop"
      )
    
    DT::datatable(stats_scenarios, options = list(pageLength = 10))
  })
  
  # =========================================================================
  # ANALYSE
  # =========================================================================
  
  output$plot_distribution <- renderPlotly({
    if (is.null(donnees_filtrees())) {
      return(plotly_empty())
    }
    
    df <- donnees_filtrees()
    
    p <- plot_ly(
      x = ~Consommation,
      data = df,
      type = "histogram",
      nbinsx = 50,
      marker = list(color = "steelblue")
    ) %>%
      layout(
        title = "Distribution de la Consommation",
        xaxis = list(title = "Consommation (MW)"),
        yaxis = list(title = "Fréquence")
      )
    
    return(p)
  })
  
  output$plot_hourly <- renderPlotly({
    if (is.null(donnees_filtrees())) {
      return(plotly_empty())
    }
    
    df <- donnees_filtrees()
    df$Heure <- hour(df$Date)
    
    stats_horaire <- df %>%
      group_by(Heure) %>%
      summarise(
        Consommation_moyenne = mean(Consommation, na.rm = TRUE),
        .groups = "drop"
      )
    
    p <- plot_ly(
      stats_horaire,
      x = ~Heure,
      y = ~Consommation_moyenne,
      type = "scatter",
      mode = "lines+markers",
      line = list(color = "orange", width = 2),
      marker = list(size = 6)
    ) %>%
      layout(
        title = "Consommation Moyenne par Heure",
        xaxis = list(title = "Heure", range = c(0, 23)),
        yaxis = list(title = "Consommation (MW)")
      )
    
    return(p)
  })
  
  output$plot_weekly <- renderPlotly({
    if (is.null(donnees_filtrees())) {
      return(plotly_empty())
    }
    
    df <- donnees_filtrees()
    df$Jour <- wday(df$Date, label = TRUE, abbr = FALSE)
    
    stats_hebdo <- df %>%
      group_by(Jour) %>%
      summarise(
        Consommation_moyenne = mean(Consommation, na.rm = TRUE),
        .groups = "drop"
      )
    
    # Réordonner les jours
    jours_ordre <- c("Lundi", "Mardi", "Mercredi", "Jeudi", "Vendredi", "Samedi", "Dimanche")
    stats_hebdo$Jour <- factor(stats_hebdo$Jour, levels = jours_ordre)
    stats_hebdo <- stats_hebdo[order(stats_hebdo$Jour), ]
    
    p <- plot_ly(
      stats_hebdo,
      x = ~Jour,
      y = ~Consommation_moyenne,
      type = "bar",
      marker = list(color = "lightgreen")
    ) %>%
      layout(
        title = "Consommation Moyenne par Jour de la Semaine",
        xaxis = list(title = "Jour"),
        yaxis = list(title = "Consommation (MW)")
      )
    
    return(p)
  })
  
  output$plot_monthly <- renderPlotly({
    if (is.null(donnees_filtrees())) {
      return(plotly_empty())
    }
    
    df <- donnees_filtrees()
    df$Mois <- month(df$Date, label = TRUE, abbr = FALSE)
    
    stats_mensuel <- df %>%
      group_by(Mois) %>%
      summarise(
        Consommation_moyenne = mean(Consommation, na.rm = TRUE),
        .groups = "drop"
      )
    
    p <- plot_ly(
      stats_mensuel,
      x = ~Mois,
      y = ~Consommation_moyenne,
      type = "bar",
      marker = list(color = "lightcoral")
    ) %>%
      layout(
        title = "Consommation Moyenne par Mois",
        xaxis = list(title = "Mois"),
        yaxis = list(title = "Consommation (MW)")
      )
    
    return(p)
  })
}

# =============================================================================
# LANCER L'APPLICATION
# =============================================================================

shinyApp(ui = ui, server = server)

