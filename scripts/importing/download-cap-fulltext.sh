#!/usr/bin/env bash

# This script downloads the latest CAP metadata and unzips the ZIP files. 
# The actual JSONL files which are XZ compressed are the responsibility 
# of the Go script to decompress.

wget --header="Accept: text/html" --mirror -np -nH -c -N --cut-dirs=5 -A zip --reject-regex '_xml' https://case.law/download/bulk_exports/latest/by_jurisdiction/case_text_open/
wget --header="Accept: text/html" --header="Authorization: Token aafcd2bbc1564fea235317df6d792d849f4043d4" --mirror -np -nH -c -N --cut-dirs=5 -A zip --reject-regex '_xml' https://case.law/download/bulk_exports/latest/by_jurisdiction/case_text_restricted/

find . -type f -iname *.zip -exec unzip -o -d fulltext_unzipped {} \;

