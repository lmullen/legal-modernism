library(tidyverse)

start_url <- "https://api.case.law/v1/volumes/"
current_url <- start_url
continue <- TRUE

volumes_api <- list()

while(continue) {
  cat("Fetching:", current_url, "\n")
  response <- jsonlite::read_json(current_url, simplifyVector = TRUE)
  results <- response$results
  next_url <- response[["next"]]

  volumes_api[[current_url]] <- results

  current_url <- next_url

  if (is.null(current_url)) {
    continue <- FALSE
  }
}

volumes_raw <- bind_rows(volumes_api)

volumes_to_jurisdictions <- volumes_raw |>
  select(barcode, jurisdictions) |>
  unnest(cols = c(jurisdictions)) |>
  select(barcode, jurisdiction = id)

volumes_raw$jurisdictions <- NULL

volumes <- volumes_raw |>
  rename(volume_number_raw = volume_number) |>
  mutate(volume_number = as.integer(volume_number_raw)) |>
  mutate(start_year = if_else(start_year == 0, NA_integer_, start_year)) |>
  mutate(end_year = if_else(end_year == 0, NA_integer_, end_year)) |>
  mutate(nominative_name = if_else(nominative_name == "", NA_character_, nominative_name)) |>
  mutate(series_volume_number = if_else(series_volume_number == "", NA_character_, series_volume_number)) |>
  select(barcode, reporter, volume_number, everything())

library(DBI)
library(dbplyr)
db <- dbConnect(odbc::odbc(), "Research", timeout = 10)

DBI::dbWriteTable(db, "volumes", volumes)
DBI::dbWriteTable(db, "volumes_to_jurisdictions", volumes_in_jurisdictions)

dbDisconnect(db)
