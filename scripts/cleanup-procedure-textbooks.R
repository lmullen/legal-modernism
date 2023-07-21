# Cleaning up the textbook data so that it has the psmid and bibliographic ID
library(tidyverse)
library(DBI)
library(dbplyr)

db <- dbConnect(odbc::odbc(), "Research", timeout = 10)
book_info <- tbl(db, in_schema("moml", "book_info")) |> collect()
book_info <- book_info |>
  select(webid, psmid, bibliographicid)
raw_tb <- read_csv("temp/procedure_textbooks.csv") |>
  select(-moml_psmid) |>
  rename(webid = moml_webid)

raw_tb |>
  left_join(book_info, by = "webid") |>
  select(bibliographicid, psmid, webid, everything()) |>
  write_csv("temp/procedure-textbooks-cleaned.csv")
