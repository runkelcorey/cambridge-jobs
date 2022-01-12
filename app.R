library(shiny)
library(readr)
library(dplyr)
library(lubridate)
library(DT)

ui <- fluidPage(
  titlePanel("City of Cambridge Job Postings"),
  sidebarLayout(
    sidebarPanel(h2("filters"),
                 sliderInput("posted",
                             "Days since posted",
                             min = 0,
                             max = 30,
                             value = 14,
                             round = TRUE),
                 checkboxGroupInput("type",
                                    "Employee type",
                                    choices = c("wage",
                                                "salary"),
                                    selected = c("wage",
                                                 "salary")),
                 sliderInput("hours",
                             "Hours per week",
                             min = 0,
                             max = 40,
                             value = c(19, 37.5),
                             round = TRUE),
                 sliderInput("pay",
                             "Annualized pay",
                             min = 0,
                             max = 250000,
                             value = c(15000,60000),
                             round = TRUE)
    ),
    mainPanel(DT::dataTableOutput("listings"))
  )
)

server <- function(input, output) {
  
  #helper function
  salaryscrubber <- function(pay_min, pay_max) {
    ifelse(is.na(pay_min), scales::dollar(pay_max, accuracy = 1), paste0(scales::dollar(pay_min, accuracy = 1), "-", scales::dollar(pay_max, accuracy = 1)))
  }
  
  #data pre-processing
  data <- read_csv("data/jobs.csv") %>%
    mutate(title = paste0("<a href='https://www2.cambridgema.gov/viewjoblisting.cfm?Job_ID=", id, "&pv=Yes'>", title, "</a>"),
           posted_trim = as_date(ifelse(posted < Sys.Date() - 30, Sys.Date() - 30, posted)),
           across(c(posted, due), ~ strftime(.x, "%b %d")),
           hours = ifelse(is.na(hours_min), hours_max, paste0(hours_min, "-", hours_max)),
           pay_min = ifelse(type == "salary", pay_min, pay_min*hours_min*50),
           pay_max = ifelse(type == "salary", pay_max, pay_max*hours_max*50),
           pay = salaryscrubber(pay_min, pay_max))
  
  #reactive filters
  filteredData <- reactive(filter(data,
                                  hours_max > input$hours[1] | hours_min < input$hours[2] | is.na(hours_max),
                                  pay_max > input$pay[1] | pay_min < input$pay[2] | is.na(pay_max),
                                  posted_trim > Sys.Date() - input$posted - 2,
                                  type %in% input$type) %>%
                             select(department, title, hours, posted, due, pay, type, requirements, responsibilities))
  
  #post-processing
  output$listings <- filteredData() %>%
    renderDataTable(options = list(columnDefs = list(list(
      targets = c(8:9),
      render = JS(
        "function(data, type, row, meta) {",
        "return type === 'display' && data.length > 15 ?",
        "'<span title=\"' + data + '\">' + data.substr(0, 15) + '...</span>' : data;",
        "}"
      )
    ))), escape = FALSE)
}

shinyApp(ui = ui, server = server)