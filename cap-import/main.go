package main

import (
	"bufio"
	"context"
	"encoding/json"
	"fmt"
	"os"

	"github.com/rs/zerolog"
	"github.com/rs/zerolog/log"
	"github.com/ulikunitz/xz"
)

func main() {

	log.Logger = log.Output(zerolog.ConsoleWriter{
		Out:             os.Stderr,
		FormatTimestamp: consoleTimeFormat,
		NoColor:         false})

	if len(os.Args) != 2 {
		log.Fatal().Msg("Please provide exactly one argument, the path to the .jsonl.xz file to be parsed")
	}

	db, err := dbConnect()
	if err != nil {
		log.Fatal().Err(err).Msg("Error connecting to database")
	}

	path := os.Args[1]
	file, err := os.Open(path)
	if err != nil {
		log.Fatal().Err(err).Msg("Error opening the file")
	}

	decompressed, err := xz.NewReader(file)
	if err != nil {
		log.Fatal().Err(err).Msg("Error decompressing the file")
	}

	var casesImported int64

	// Scan line by line, but into a large buffer in case there are large cases
	scanner := bufio.NewScanner(decompressed)
	buf := make([]byte, 0, 128*1024)
	scanner.Buffer(buf, 128*1024)
	for scanner.Scan() {
		// Read in one case per line
		c := &Case{}
		json.Unmarshal(scanner.Bytes(), c)
		if err := scanner.Err(); err != nil {
			log.Fatal().Err(err).Msg("Error scanning file")
		}
		err = c.Save(context.Background(), db)
		if err != nil {
			log.Fatal().Err(err).Msg("Error saving case to database")
		}
		casesImported += 1
	}

	fmt.Printf("Imported %v cases from %s", casesImported, path)

}
