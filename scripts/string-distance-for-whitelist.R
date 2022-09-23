library(tidyverse)
library(dbplyr)
library(DBI)
library(stringdist)

db <- dbConnect(odbc::odbc(), "Research", timeout = 10)

wl <- tbl(db, in_schema("legalhist", "reporters_citation_to_cap")) |> collect()
rep <- tbl(db, in_schema("cap", "reporters")) |>
  collect()

standard <- wl |>
  filter(!junk,
         !statute,
         !uk) |>
  pull(reporter_standard)
cap <- wl |>
  filter(!junk,
         !statute,
         !uk) |>
  pull(reporter_cap)
cap_orig <- rep$short_name

known_good <- c(standard, cap, cap_orig) |> sort() |> unique()

guess_reporter <- function(x) {
  dists1 <- stringsim(x, known_good, method = "lv")
  names(dists1) <- known_good
  dists2 <- stringsim(x, known_good, method = "jaccard")
  names(dists2) <- known_good
  dists <- c(dists1, dists2)
  dists <- sort(dists, decreasing = TRUE)
  dists <- dists[dists >= 0.75]
  dists <- dists |> head(10)
  guesses <- dists |> names() |> unique()
  guesses
}

to_clean <- tbl(db, in_schema("output", "top_reporters_not_whitelisted")) |>
  arrange(desc(n)) |>
  head(1000) |>
  collect()

to_clean$guesses <- vector("list", nrow(to_clean))

for (i in seq_len(nrow(to_clean))) {
  guesses <- guess_reporter(to_clean$reporter_found[i])
  guesses <- list(guesses)
  to_clean$guesses[i] <- guesses
}

to_clean |>
  unnest(guesses, keep_empty = TRUE) |>
  group_by(reporter_found) |>
  mutate(guess_num = seq_along(reporter_found)) |>
  pivot_wider(names_from = guess_num, values_from = guesses, names_prefix = "guess_") |>
  write_csv("~/Desktop/with-suggestions.csv", na = "")
