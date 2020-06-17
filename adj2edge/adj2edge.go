// This script turns a network stored as an adjacency list into a network stored as an edge list.
package main

import (
	"bufio"
	"log"
	"os"
	"strings"
)

func main() {
	if len(os.Args) != 3 {
		log.Fatalln("Pass in exactly two arguments, the path to the input file and the path to the output file.")
	}

	// Check that the input file exists
	inFilePath := os.Args[1]
	inFile, err := os.Open(inFilePath)
	if err != nil {
		log.Printf("There was a problem with this file: %s\n", inFilePath)
		log.Fatalln(err)
	}
	defer inFile.Close()
	in := bufio.NewScanner(inFile)

	// Set up a csv file to write output
	outFilePath := os.Args[2]
	outFile, err := os.Create(outFilePath)
	if err != nil {
		log.Printf("Cannot create this file: %s\n", outFilePath)
		log.Fatalln(err)
	}
	defer outFile.Close()
	out := bufio.NewWriter(outFile)

	// Write a header row for the CSV file
	header := formatRow("cites_from", "cites_to")
	out.WriteString(header)

	// Iterate over each line in the input file
	for in.Scan() {
		line := in.Text()

		// The first number in the table is the case that is doing the citing. The rest of the numbers are the cases being
		// cited.
		splits := strings.Split(line, ",")
		citesFrom, citesTo := splits[0], splits[1:]

		// Write each instance of a citation to the output file
		for _, cited := range citesTo {
			out.WriteString(formatRow(citesFrom, cited))
		}

	}

	out.Flush()

}

func formatRow(a, b string) string {
	return a + "," + b + "\n"
}
