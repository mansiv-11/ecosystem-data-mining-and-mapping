library(mailR)
library(httr)
library(jsonlite)

# Function to load OAuth 2.0 client credentials from a JSON file
load_credentials <- function(json_file_path) {
  credentials <- fromJSON(json_file_path)
  return(credentials)
}

# Function to get authorization token using OAuth 2.0 client credentials
get_auth_token <- function(credentials) {
  # You would need to implement OAuth flow here or use a stored refresh token
  # This is a placeholder function
  return("your_oauth_token")
}

# Function to check emails with the specified subject
check_emails <- function(auth_token) {
  url <- "https://gmail.googleapis.com/gmail/v1/users/me/messages?q=subject:opportunity is:unread"
  response <- httr::GET(url, add_headers(Authorization = paste("Bearer", auth_token)))
  emails <- jsonlite::fromJSON(content(response, "text"), flatten = TRUE)
  
  if (!is.null(emails$messages)) {
    return(emails$messages$id)
  } else {
    return(character(0)) # Return an empty character vector if no messages
  }
}

# Function to send an email notification
send_notification <- function(email_subject, sender_email) {
  send.mail(from = "your_email@example.com",
            to = "your_notification_recipient@example.com",
            subject = "New Opportunity Email Alert",
            body = sprintf("You have a new email about an opportunity: '%s' from %s", email_subject, sender_email),
            smtp = list(host.name = "smtp.example.com", port = 465, user.name = "your_email@example.com", passwd = "your_password", ssl = TRUE),
            authenticate = TRUE,
            send = TRUE)
}

# Main routine
json_file_path <- "/Users/rampal/Downloads/Project-R/googlealerts.json"  # Replace with the path to your JSON file
credentials <- load_credentials(json_file_path)
auth_token <- get_auth_token(credentials)
email_ids <- check_emails(auth_token)

for (email_id in email_ids) {
  # Fetch each email by ID to get details (subject, sender)
  email_details_url <- sprintf("https://gmail.googleapis.com/gmail/v1/users/me/messages/%s", email_id)
  email_response <- httr::GET(email_details_url, add_headers(Authorization = paste("Bearer", auth_token)))
  email_info <- jsonlite::fromJSON(content(email_response, "text"), flatten = TRUE)
  
  email_subject <- email_info$payload$headers[which(email_info$payload$headers$name == "Subject")]$value
  sender_email <- email_info$payload$headers[which(email_info$payload$headers$name == "From")]$value
  
  send_notification(email_subject, sender_email)
}

