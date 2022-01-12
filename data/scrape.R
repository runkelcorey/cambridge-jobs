library(tidyverse)
library(rvest)

urls <- read_html("https://www2.cambridgema.gov/jobopenings.cfm?pv=Yes") %>%
  html_elements("table.textArial tr td:nth-child(2) a") %>%
  html_attr("href") %>%
  paste("https://www2.cambridgema.gov/", ., "&pv=Yes", sep = "")

names(urls) <- map(urls, ~ parse_number(substring(.x, 50)))

details <- function(x) {
  read_html(x) %>%
    html_element(css = ".textarial .textarial") %>%
    html_table(trim = TRUE)
}

listings <- map_df(urls, details, .id = "id") %>%
  pivot_wider(names_from = "X1", names_sep = ":", values_from = "X2")

dates <- map_df(urls, ~ html_text2(html_element(read_html(.x), css = "center"))) %>%
  pivot_longer(everything(), names_to = "id", values_to = "dates") %>%
  separate(dates, c(NA, NA, "posted", "due", NA), sep = "\n") %>%
  mutate(across(posted:due, ~ lubridate::parse_date_time(.x, "mdy")))

rest <- map_df(urls, ~ html_text2(html_element(read_html(.x), css = "tr:nth-child(3) td")), .id = "id") %>%
  pivot_longer(everything(), names_to = "id", values_to = "text") %>%
  separate_rows(text, sep = "\n+") %>%
  filter(grepl("\\w+", text)) %>%
  mutate(section = case_when(grepl("ESSENTIAL DUTIES AND RESPONSIBILITIES", text) ~ "responsibilities",
                             grepl("MINIMUM REQUIREMENTS:", text) ~ "requirements",
                             grepl("PREFERRED:", text) ~ "preferred",
                             grepl("OTHER INFORMATION:", text) ~ "other",
                             grepl("RATE:", text) ~ "pay",
                             grepl("APPLICATION PROCEDURE:", text) ~ "rest")) %>%
  fill(section, .direction = "down") %>%
  filter(!is.na(section), section %in% c("responsibilities", "requirements", "preferred", "pay"),  str_detect(str_remove_all(text, ":|\\s"), "^[A-Z]+$", negate = T)) %>%
  group_by(id, section) %>%
  summarize(text = paste0(text, collapse = "\n")) %>%
  pivot_wider(id_cols = id, names_from = "section", values_from = "text")

jobs <- inner_join(listings, dates) %>%
  inner_join(rest) %>%
  rename(department = 2, title = 3, code = 4, civil = 5, union = 6, hours = 7) %>%
  mutate(union = ifelse(union == "None", NA, union),
         civil = ifelse(grepl("Non", civil), FALSE, TRUE),
         type = ifelse(grepl("hour", pay), "wage", "salary"),
         pay = str_replace(pay, " to |–", "-"),
         hours = str_replace(str_replace(str_remove(substr(hours, 1, 10), "-h"), "[u|U]p", "0"), " to ", "-")) %>%
  separate(hours, c("hours_min", "hours_max"), sep = "-", fill = "left") %>%
  separate(pay, c("pay_min", "pay_max"), sep = "-", fill = "left") %>%
  mutate(across(c(department, code, union, type), as_factor),
         across(c(hours_min, hours_max, pay_min, pay_max), parse_number),
         across(c(posted, due), lubridate::ymd)) %>%
  bind_rows(read_csv("data/jobs.csv", col_types = "cfcfl?nnDDnncccf", show_col_types = FALSE)) %>%
  distinct(id, .keep_all = TRUE)

write_csv(jobs, "data/jobs.csv")
