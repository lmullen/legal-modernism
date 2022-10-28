# Importing CAP data

This directory contains scripts for importing CAP data. Entities which can entirely, or at least mostly, be created from the bulk data are done using that. Some entities can only be pulled in their entirety from the API.

The `download-cap-metadata.sh` script will download the CAP metadata (not full text) files.

The `download-cap-fulltext.sh` script will download the CAP full text. You must add the access token.

Run those two scripts from some temporary directory.

The `create-cap-metadata-tables.sql` will create the CAP metadata tables in the database.

The script `fetch-cap-reporters.R` will get the reporters from the API and save them to the database, creating two tables: `reporters` and `reporters_to_jurisdictions`.

The script `fetch-cap-volumes.R` will get the volumes from the API and save them to the database, creating two tables: `volumes` and `volumes_to_jurisdictions`.

The Go program `cap-metadata-import` will import the data from the bulk metadata downloads to the `cases`, `citations`, `courts`, and `jurisdictions` tables. After being build with `go install`, it can be run over all the bulk data files with an invocation like this one: `find metadata_unzipped -type f -iname *.jsonl.xz -exec cap-import {} \;`.

The `attorneys`, `headnotes`, `judges`, `opinions`, and `parties`, and `summaries` tables are a part of the restricted, full-text bulk downloads. These have not yet been implemented.
