library(tidyverse)

raw <- read_csv("~/Downloads/reporters_citation_to_cap_whitelist-2.csv")

raw |>
  mutate(
    statute = if_else(is.na(statute), FALSE, statute),
    uk = if_else(is.na(uk), FALSE, uk),
  ) |>
  write_csv("~/Desktop/reporter-whitelist.csv", na = "")
