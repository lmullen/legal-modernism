package main

import (
	"fmt"
	"io/ioutil"
	"time"

	"github.com/lmullen/legal-modernism/go/citations"
	"github.com/lmullen/legal-modernism/go/treatises"
	log "github.com/sirupsen/logrus"
)

func main() {

	file := "../sample-treatises/Pomeroy, Remedies, 1976.txt"
	text, err := ioutil.ReadFile(file)
	if err != nil {
		log.WithError(err).Fatal("Error reading sample treatise")
	}

	treatise := &treatises.Page{
		DocID:    file,
		FullText: string(text),
	}

	// Dummy treatise with the
	// treatise := &treatises.Page{
	// 	DocID:    "test",
	// 	PageID:   "test",
	// 	FullText: "This has a citation 193 Fl. Rpts. 203 inside it.",
	// }

	log.WithField("treatise", treatise).Println("Successfully loaded treatise")

	start := time.Now()

	genericDetector := citations.NewDetector("Generic", `[\w\s\.]+?`)

	citations := genericDetector.Detect(treatise)

	elapsed := time.Since(start)

	for _, cite := range citations {
		fmt.Println(cite)
	}

	log.Printf("Detection and printing took %s\n", elapsed)

}
