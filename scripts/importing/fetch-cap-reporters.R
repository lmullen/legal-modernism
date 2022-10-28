library(tidyverse)

start_url <- "https://api.case.law/v1/reporters/"
current_url <- start_url
continue <- TRUE

reporters_api <- list()

while(continue) {
  response <- jsonlite::read_json(current_url, simplifyVector = TRUE)
  results <- response$results
  next_url <- response[["next"]]

  reporters_api[[current_url]] <- results

  current_url <- next_url

  if (is.null(current_url)) {
    continue <- FALSE
  }
}

reporters_raw <- bind_rows(reporters_api)

reporters_to_jurisdictions <- reporters_raw |>
  select(reporter_id = id, jurisdictions) |>
  unnest(cols = c(jurisdictions)) |>
  select(reporter_id, jurisdiction_id = id)

reporters_raw$jurisdictions <- NULL
reporters <- reporters_raw

library(DBI)
library(dbplyr)
db <- dbConnect(odbc::odbc(), "Research", timeout = 10)

DBI::dbWriteTable(db, "reporters", reporters)
DBI::dbWriteTable(db, "reporters_to_jurisdictions", reporters_to_jurisdictions)

dbDisconnect(db)
