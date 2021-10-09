package main

import (
	"fmt"
	"io/ioutil"
	"time"

	log "github.com/sirupsen/logrus"
)

func main() {

	file := "../sample-treatises/Pomeroy, Remedies, 1976.txt"
	text, err := ioutil.ReadFile(file)
	if err != nil {
		log.WithError(err).Fatal("Error reading sample treatise")
	}

	treatise := &Treatise{id: file, text: string(text)}
	log.WithField("treatise", treatise).Println("Successfully loaded treatise")

	start := time.Now()

	// abbreviations := []string{
	// 	`Cal\.`,
	// 	`N\.\s*Y\.`,
	// 	`Mo\.`,
	// 	`Mass\.`,
	// 	`Pa\.`,
	// 	`Kans\.`,
	// 	`How\.\s*Pr\.`,
	// 	`Barb\.`,
	// }

	abbreviations := []string{
		`\w+\.*`,
	}

	var reporters []*CiteDetector
	for _, abbr := range abbreviations {
		reporter := NewCiteDetector(abbr, abbr)
		reporters = append(reporters, reporter)
	}

	for _, reporter := range reporters {
		matches := reporter.Detect(treatise)
		for _, match := range matches {
			fmt.Println(match)
		}
	}

	elapsed := time.Since(start)
	log.Printf("Detection and printing took %s\n", elapsed)

}
