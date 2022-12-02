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
		log.Fatal().Msg("provide exactly one argument, the path to the .jsonl.xz file to be parsed")
	}

	db, err := dbConnect()
	if err != nil {
		log.Fatal().Err(err).Msg("error connecting to database")
	}

	path := os.Args[1]
	file, err := os.Open(path)
	if err != nil {
		log.Fatal().Err(err).Msg("error opening the file")
	}

	decompressed, err := xz.NewReader(file)
	if err != nil {
		log.Fatal().Err(err).Msg("error decompressing the file")
	}

	var casesImported int64

	// Scan line by line, but into a large buffer in case there are large cases
	scanner := bufio.NewScanner(decompressed)
	maxSize := 1024 * 1000 * 1000 * 2 // 2 gigabytes
	buf := make([]byte, 0, maxSize)
	scanner.Buffer(buf, maxSize)
	for scanner.Scan() {
		// Read in one case per line
		c := &Case{}
		err = json.Unmarshal(scanner.Bytes(), c)
		if err != nil {
			log.Fatal().Err(err).Msg("error unmarshalling case JSON")
		}
		// log.Info().Msg(fmt.Sprint(c.ID))
		if err := scanner.Err(); err != nil {
			log.Fatal().Err(err).Msg("error scanning file")
		}
		err = c.Save(context.Background(), db)
		if err != nil {
			log.Fatal().Err(err).Msg("error saving case to database")
		}
		casesImported += 1
	}

	fmt.Printf("imported %v cases from %s\n", casesImported, path)

}
