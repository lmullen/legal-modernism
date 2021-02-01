# This script cleans up the citations graph from Caselaw Access Project to the database:
#   https://case.law/download/citation_graph/
#
# It assumes that you have already done the following:
#   1. Downloaded and decompressed the data.
#   2. Run the `adj2edge` script to turn the adjacency list into an edge list.
#   3. Removed the existing tables from the database.
#
# It then creates clean versions of the data and the schema in the database. For
# speed's sake, it's faster to then just load the CSVs into the database using psql.


BASEDIR <- "~/Downloads"

library(DBI)
library(dbplyr)
library(dplyr)
library(fs)
library(readr)
library(stringr)

citations <- read_csv(path(BASEDIR, "citations-edge.csv"), col_types =
                        cols(
                          cites_from = col_integer(),
                          cites_to = col_integer()
                        ))
metadata <- read_csv(path(BASEDIR, "metadata.csv"), col_types =
                       cols(
                         id = col_integer(),
                         frontend_url = col_character(),
                         jurisdiction__name = col_character(),
                         jurisdiction_id = col_integer(),
                         court__name_abbreviation = col_character(),
                         court_id = col_integer(),
                         reporter__short_name = col_character(),
                         reporter_id = col_integer(),
                         name_abbreviation = col_character(),
                         decision_date_original = col_character(),
                         cites = col_character()
                       ))
pagerank <- read_csv(path(BASEDIR, "pagerank_scores.csv"), col_types =
                       cols(
                         id = col_integer(),
                         raw_score = col_double(),
                         percentile = col_double()
                       ))

# The metadata needs to have its dates cleaned up. Parse out a year and then do
# the best we can with the dates.
metadata <- metadata %>%
  rename(court_name_abbreviation = court__name_abbreviation) %>%
  mutate(decision_year = str_sub(decision_date_original, 1, 4) %>% as.integer()) %>%
  mutate(decision_date = as.Date(decision_date_original))

# Then write out the metadata again.
write_csv(metadata, path(BASEDIR, "metadata-clean.csv"))

# Connect to the database
law_db <- dbConnect(odbc::odbc(), "Law", timeout = 10)

# Create the database tables
dbCreateTable(law_db, Id(schema = "cap_citations", table = "metadata"),
              metadata, overwrite = TRUE)
dbCreateTable(law_db, Id(schema = "cap_citations", table = "pagerank"),
              pagerank, overwrite = TRUE)
dbCreateTable(law_db, Id(schema = "cap_citations", table = "citations"),
              citations, overwrite = TRUE)
