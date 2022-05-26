#!/usr/bin/env bash

# This script downloads the latest CAP metadata and unzips the ZIP files. 
# The actual JSONL files which are XZ compressed are the responsibility 
# of the Go script to decompress.

wget --header="Accept: text/html" --mirror -np -nH -c -N --cut-dirs=4 -A zip https://case.law/download/bulk_exports/latest/by_jurisdiction/case_metadata/

find case_metadata -type f -iname *.zip -exec unzip -o -d metadata_unzipped {} \;

