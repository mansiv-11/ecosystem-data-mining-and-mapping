library(shiny)
library(readxl)

# Load your data
data <- read_excel("/Users/rampal/Downloads/Project-R/TEST Funding Opportunities.xlsx")

# Define UI
ui <- fluidPage(
  titlePanel("Opportunity Explorer"),
  
  sidebarLayout(
    sidebarPanel(
      selectInput("type", "Select Type", choices = unique(data$Type)),
      selectInput("location", "Select Location", choices = unique(data$Location)),
      actionButton("goButton", "Go")
    ),
    
    mainPanel(
      uiOutput("opportunitiesGrid")
    )
  ),
  
  # Include Bootstrap and your custom CSS
  tags$head(
    tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
  )
)

# Define server logic
server <- function(input, output, session) {
  
  output$opportunitiesGrid <- renderUI({
    input$goButton
    
    isolate({
      if (!is.null(input$type)) {
        filtered_data <- data[data$Type == input$type & data$Location == input$location, ]
        
        # Create a card for each opportunity
        cards <- lapply(1:nrow(filtered_data), function(i) {
          opportunity <- filtered_data[i, ]
          div(class = "col-sm-4",
              div(class = "card", style = "width: 18rem; margin-bottom: 20px;",
                  img(src = opportunity$Image, class = "card-img-top", alt = "Opportunity image"),
                  div(class = "card-body",
                      h5(class = "card-title", opportunity$Title),
                      p(class = "card-text", opportunity$Description),
                      p(class = "card-text", strong("Close Date: "), opportunity$Deadline),
                      # Placeholder for your buttons, you'll have to implement the actual functionality
                      actionButton(inputId = paste("like_btn_", i, sep = ""), label = "Like", class = "btn btn-primary"),
                      actionButton(inputId = paste("dislike_btn_", i, sep = ""), label = "Dislike", class = "btn btn-secondary")
                  )
              )
          )
        })
        
        do.call(tagList, cards)
      }
    })
  })
}

# Run the application
shinyApp(ui = ui, server = server)
