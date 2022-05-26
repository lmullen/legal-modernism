package main

import (
	"bufio"
	"fmt"
	"os"
	"time"

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

	path := os.Args[1]
	file, err := os.Open(path)
	if err != nil {
		log.Fatal().Err(err).Msg("Error opening the file")
	}

	decompressed, err := xz.NewReader(file)
	if err != nil {
		log.Fatal().Err(err).Msg("Error decompressing the file")
	}

	scanner := bufio.NewScanner(decompressed)
	buf := make([]byte, 0, 128*1024)
	scanner.Buffer(buf, 128*1024)
	// optionally, resize scanner's capacity for lines over 64K, see next example
	x := 0
	for scanner.Scan() {
		fmt.Println(scanner.Text())
		x += 1
		if x > 100 {
			log.Fatal().Msg("quitting")
		}
	}

	if err := scanner.Err(); err != nil {
		log.Error().Err(err).Msg("Error scanning file")
	}

}

// consoleTimeFormat sets a simple format for the pretty logs without colors
func consoleTimeFormat(i interface{}) string {
	ts := i.(string)
	t, err := time.Parse(time.RFC3339, ts)
	if err != nil {
		return fmt.Sprint(i)
	}
	return t.Format(time.Kitchen)
}
