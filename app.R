library(shiny)
library(readr)
library(dplyr)
library(lubridate)
library(DT)

ui <- fluidPage(
  titlePanel("City of Cambridge Job Postings"),
  mainPanel(DTOutput("listings"))
)

server <- function(input, output) {
  
  #data pre-processing
  data <- read_csv("https://raw.githubusercontent.com/runkelcorey/cambridge-jobs/main/data/jobs.csv") %>%
    filter(open = TRUE) %>%
    mutate(title = paste0("<a href='https://www2.cambridgema.gov/viewjoblisting.cfm?Job_ID=", id, "&pv=Yes'>", title, "</a>"),
           pay_min = ifelse(type == "salary", pay_min, pay_min*hours_min*50),
           pay_max = ifelse(type == "salary", pay_max, pay_max*hours_max*50),
           type = as.factor(type))
  
  output$listings <- data %>%
    select(department, title, posted, due, open, hours_max, pay_min, pay_max, type, requirements, responsibilities) %>%
    rename("max hours" = hours_max, "min salary" = pay_min, "max salary" = pay_max) %>%
    datatable(filter = "top",
              extensions = 'Buttons',
              options = list(
                order = list(3, "desc"),
                dom = 'Bfrtip',
                buttons = c('copy', 'csv'),
                columnDefs = list(list(
                targets = c(10:11),
                render = JS(
                  "function(data, type, row, meta) {",
                  "return type === 'display' && data.length > 30 ?",
                  "'<span title=\"' + data + '\">' + data.substr(0, 30) + '...</span>' : data;",
                  "}"
                )
              ))), escape = FALSE) %>%
    formatCurrency(digits = 0, columns = c("min salary", "max salary")) %>%
    formatDate(columns = c("posted", "due"), method = "toLocaleDateString") %>%
    renderDT(server = FALSE)
}

shinyApp(ui = ui, server = server)