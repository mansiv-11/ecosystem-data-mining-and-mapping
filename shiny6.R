library(shiny)
library(DBI)
library(RSQLite)
library(shinyjs)
library(fontawesome)

# Connect to the database
conn <- dbConnect(RSQLite::SQLite(), dbname = "updated_database.db")

# Fetch distinct location and type values for filters
locations <- c("All", dbGetQuery(conn, "SELECT DISTINCT Location FROM opportunities")$Location)
types <- c("All", dbGetQuery(conn, "SELECT DISTINCT Type FROM opportunities")$Type)

# Define UI for application
ui <- fluidPage(
  useShinyjs(),
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
  ),
  h1("Opportunities", class = "text-center"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("location", "Select a Location:", choices = locations),
      selectInput("type", "Select a Type:", choices = types),
      actionButton("submit", "Submit", class = "btn-primary")
    ),
    mainPanel(
      uiOutput("mainContent")
    )
  )
)

# Define server logic required to display and filter opportunities
server <- function(input, output, session) {
  opportunities <- reactiveVal(data.frame())
  
  observeEvent(input$submit, {
    query <- "SELECT * FROM opportunities"
    if (input$location != "All") {
      query <- paste0(query, " WHERE Location = '", input$location, "'")
    }
    if (input$type != "All") {
      query <- ifelse(input$location != "All", paste0(query, " AND"), paste0(query, " WHERE"))
      query <- paste0(query, " Type = '", input$type, "'")
    }
    
    opportunities(dbGetQuery(conn, query))
    
    # Simplify descriptions for the grid view
    simplified_descriptions <- sapply(opportunities()$Description, function(desc) {
      if (nchar(desc) > 100) {
        return(paste0(substr(desc, 1, 100), "..."))
      } else {
        return(desc)
      }
    })
    
    output$opportunitiesGrid <- renderUI({
      fluidRow(
        lapply(1:nrow(opportunities()), function(i) {
          column(width = 4,
                 div(class = "card h-100",
                     div(class = "card-img-top", style = "position: relative; background-image: url('generic_image.png'); background-size: cover; background-position: center center; background-repeat: no-repeat; height: 190px;",
                         img(src = "images.png", style = "position: absolute; top: 90%; left: 50%; transform: translate(-50%, -50%); width: 100px; height: auto;")
                     ),
                     div(class = "card-body", style = "text-align: center;",
                         p(class = "card-type", strong(opportunities()$Type[i])),
                         h5(class = "card-title", opportunities()$Title[i]),  # Ensure the title is displayed below the type
                         p(class = "card-text", simplified_descriptions[i]),  # Use the simplified description
                         p(class = "card-text", strong("Close Date: "), opportunities()$Deadline[i])
                     ),
                     div(class = "card-footer",
                         actionButton(inputId = paste("detail_btn_", i, sep = ""), label = "View Details", class = "btn btn-primary")
                     )
                 )
          )
        })
      )
    })
    
    output$mainContent <- renderUI({
      uiOutput("opportunitiesGrid")
    })
  })
  
  lapply(1:1000, function(i) {
    observeEvent(input[[paste("detail_btn_", i, sep = "")]], {
      if (nrow(opportunities()) >= i) {
        selected_opportunity <- opportunities()[i,]
        
        output$mainContent <- renderUI({
          fluidPage(
            tags$head(
              tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
            ),
            div(class = "detail-view",
                div(class = "detail-header", style = "background-image: url('generic_image.png'); background-size: cover; background-position: center; height: 200px; position: relative;",  # Adjusted height and width
                    div(style = "position: absolute; top: 10px; right: 10px; display: flex; gap: 10px;",
                        actionButton("comment_btn", label = "", icon = icon("comment"), class = "btn btn-light"),
                        actionButton("like_btn", label = "", icon = icon("thumbs-up"), class = "btn btn-light"),
                        actionButton("dislike_btn", label = "", icon = icon("thumbs-down"), class = "btn btn-light")
                    )
                ),
                div(class = "info-section",
                    div(class = "info-text",
                        h2(selected_opportunity$Title, class = "detail-title"),
                        p(strong("Date Posted: "), selected_opportunity$Date_Posted),
                        p(strong("Close Date: "), selected_opportunity$Deadline),
                        p(strong("Eligibility Requirements: "), selected_opportunity$Eligibility),
                        p(strong("Industry: "), selected_opportunity$Industry)
                    ),
                    div(class = "info-buttons",
                        a(href = "#", class = "btn btn-primary", "Apply"),
                        a(href = "#", class = "btn btn-secondary", "Save")
                    )
                ),
                div(class = "social-buttons",
                    a(href = "#", icon("facebook"), class = "btn btn-light"),
                    a(href = "#", icon("twitter"), class = "btn btn-light"),
                    a(href = "#", icon("linkedin"), class = "btn btn-light"),
                    a(href = "#", icon("envelope"), class = "btn btn-light"),
                    a(href = "#", icon("whatsapp"), class = "btn btn-light")
                ),
                div(style = "clear: both;"),
                div(class = "general-info",
                    h3("General Information"),
                    div(class = "general-info-item", p(strong("Category of Funding Activity: "), selected_opportunity$Category)),
                    div(class = "general-info-item", p(strong("Estimated Total Program Funding: "), selected_opportunity$Funding)),
                    div(class = "general-info-item", p(strong("Expected # of Awards: "), selected_opportunity$Awards)),
                    div(class = "general-info-item", p(strong("Funding Instrument Type: "), selected_opportunity$Instrument))
                ),
                h3("Description"),
                p(selected_opportunity$Description),
                h4("Comments"),
                div(class = "form-group",
                    tags$textarea(id = "comment", class = "form-control", rows = 3, placeholder = "Add a comment")
                ),
                actionButton("submit_comment", "Submit")
            )
          )
        })
      }
    })
  })
  
  observeEvent(input$back, {
    output$mainContent <- renderUI({
      fluidRow(
        lapply(1:nrow(opportunities()), function(i) {
          column(width = 4,
                 div(class = "card h-100", id = paste("card_", i, sep = ""), 
                     div(class = "card-img-top", style = "position: relative; background-image: url('generic_image.png'); background-size: cover; background-position: center center; background-repeat: no-repeat; height: 150px;",  # Adjusted height
                         img(src = "images.png", style = "position: absolute; top: 90%; left: 50%; transform: translate(-50%, -50%); width: 100px; height: auto;")
                     ),
                     div(class = "card-body", style = "text-align: center;",
                         p(class = "card-type", strong(opportunities()$Type[i])),
                         h5(class = "card-title", opportunities()$Title[i]),  # Ensure the title is displayed below the type
                         p(class = "card-text", opportunities()$Description[i]),
                         p(class = "card-text", strong("Close Date: "), opportunities()$Deadline[i])
                     ),
                     div(class = "card-footer",
                         actionButton(inputId = paste("detail_btn_", i, sep = ""), label = "View Details", class = "btn btn-primary")
                     )
                 )
          )
        })
      )
    })
  })
}

# Run the application 
shinyApp(ui = ui, server = server)