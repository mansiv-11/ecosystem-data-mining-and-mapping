library(shiny)
library(DBI)
library(RSQLite)
library(DT)

# Connect to the database
conn <- dbConnect(RSQLite::SQLite(), "updated_database.db")

# Fetch distinct location and type values for filters
locations <- dbGetQuery(conn, "SELECT DISTINCT Location FROM opportunities")$Location
types <- dbGetQuery(conn, "SELECT DISTINCT Type FROM opportunities")$Type

# Append 'All' option to the dropdown lists
locations <- c("All", locations)
types <- c("All", types)

# Define the UI with the dropdowns and submit button in the sidebar panel below the heading
ui <- fluidPage(
  tags$head(
    tags$style(HTML("
      /* Custom CSS for DataTable */
      .dataTables_wrapper .dataTable thead th, 
      .dataTables_wrapper .dataTable tbody td {
        border-right: 1px solid #ddd; /* Vertical lines */
        padding: 1px 4px; /* Reduced padding for content */
        line-height: 1; /* Tighter line height for less vertical space */
      }
      .dataTables_wrapper .dataTable thead th {
        border-bottom: 1px solid #ddd; /* Horizontal lines for header */
        background-color: #2196F3; /* Background color for the header (blue shade) */
        color: white; /* Font color for the header */
        border-top: 1px solid #ddd; /* Top border for header box */
        border-left: 1px solid #ddd; /* Left border for header box */
        font-family: 'Roboto', sans-serif; /* Change font family */
      }
      .dataTables_wrapper .dataTable tbody tr {
        border-bottom: 1px solid #ddd; /* Horizontal lines for rows */
        height: auto; /* Adjust height dynamically */
        font-family: 'Roboto', sans-serif; /* Change font family */
      }
      .dataTables_wrapper .dataTable thead {
        box-shadow: 0 2px 3px rgba(0,0,0,0.2); /* Box shadow for the header 'box' */
        font-family: 'Roboto', sans-serif; /* Change font family */
      }
      /* Set minimum width for Description column, assuming it is the fourth column */
      .dataTables_wrapper .dataTable tbody td:nth-child(5), 
      .dataTables_wrapper .dataTable thead th:nth-child(5) {
        min-width: 300px; /* Adjust as necessary for your content */
      }
      /* Custom styling for the 'Opportunities' heading */
      .opportunities-heading {
        font-size: 28px; /* Increase font size */
        color: #2196F3; /* Change font color to match header */
        font-weight: bold; /* Add bold font weight */
        text-shadow: 2px 2px 4px rgba(0,0,0,0.3); /* Add text shadow */
      }
    ")),
    tags$link(rel = "stylesheet", href = "https://fonts.googleapis.com/css2?family=Roboto:wght@400;700&display=swap")  # Include Google Font
  ),
  h1("Opportunities", align = "left", class = "opportunities-heading"),
  tags$div(class = "dYYAhb M0FGwd KHCwJ"),  # Your custom div here
  sidebarLayout(
    sidebarPanel(
      selectInput("location", "Select a Location:", choices = locations),
      selectInput("type", "Select a Type:", choices = types),
      actionButton("submit", "Submit", class = "btn-primary")
    ),
    mainPanel(
      DTOutput("opportunities")
    )
  )
)

# Define the server logic
server <- function(input, output) {
  observeEvent(input$submit, {
    query <- "SELECT * FROM opportunities"
    if (input$location != "All") {
      query <- paste0(query, " WHERE Location = '", input$location, "'")
      if (input$type != "All") {
        query <- paste0(query, " AND Type = '", input$type, "'")
      }
    } else if (input$type != "All") {
      query <- paste0(query, " WHERE Type = '", input$type, "'")
    }
    
    opportunities <- dbGetQuery(conn, query)
    
    output$opportunities <- renderDT({
      datatable(
        opportunities,
        options = list(
          pageLength = 10,
          autoWidth = TRUE,
          columnDefs = list(
            list(
              targets = 7,  
              render = JS(
                "function(data, type, full, meta) {
                  if (type === 'display' && data != null && data.startsWith('http')) {
                    return '<a href=\"' + data + '\" style=\"color: #0044cc;\">' + data + '</a>'; // Links in blue
                  }
                  return data;
                }"
              )
            )
          ),
          initComplete = JS(
            "function(settings, json) {
              // Initialize Bootstrap tooltips
              $('[data-toggle=\"tooltip\"]').tooltip();
            }"
          )
        ),
        escape = FALSE  
      )
    })
  })
}

# Run the Shiny application
shinyApp(ui, server)
