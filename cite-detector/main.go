package main

import (
	"context"
	"fmt"
	"io/ioutil"
	"time"

	"github.com/lmullen/legal-modernism/go/citations"
	"github.com/lmullen/legal-modernism/go/db"
	"github.com/lmullen/legal-modernism/go/treatises"
	log "github.com/sirupsen/logrus"
)

func main() {

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	db, err := db.Connect(ctx)
	if err != nil {
		log.WithError(err).Fatal("Error connecting to database")
	}
	defer db.Close()

	citeRepo := citations.NewPgxRepo(db)

	file := "../sample-treatises/Pomeroy, Remedies, 1976.txt"
	text, err := ioutil.ReadFile(file)
	if err != nil {
		log.WithError(err).Fatal("Error reading sample treatise")
	}

	treatise := &treatises.Page{
		DocID:    "19005095000",
		PageID:   "00010",
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

	genericDetector := citations.NewDetector("Generic", `[\w\s\.]{4,15}?`)

	citations := genericDetector.Detect(treatise)

	elapsed := time.Since(start)

	for _, cite := range citations {
		fmt.Println(cite)
		err := citeRepo.Save(context.TODO(), cite)
		if err != nil {
			log.WithError(err).Fatal("Error saving citation to database")
		}
	}

	log.Printf("Detection and printing took %s\n", elapsed)

}
