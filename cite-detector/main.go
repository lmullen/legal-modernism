package main

import (
	"context"
	"time"

	"github.com/lmullen/legal-modernism/go/citations"
	"github.com/lmullen/legal-modernism/go/db"
	"github.com/lmullen/legal-modernism/go/sources"
	"github.com/schollz/progressbar/v3"
	log "github.com/sirupsen/logrus"
)

func main() {
	log.Info("Starting the citation detector")

	// Book keeping
	// 	// Don't take up all of Baird's CPUS
	// 	runtime.GOMAXPROCS(20)
	// 	var wg sync.WaitGroup

	startup, cancel := context.WithTimeout(context.Background(), 120*time.Second)
	defer cancel()

	log.Info("Connecting to database")
	db, err := db.Connect(startup)
	if err != nil {
		log.WithError(err).Fatal("Error connecting to database")
	}
	defer db.Close()
	log.Info("Connected to the database")

	// Create the repositories
	sourcesDB := sources.NewPgxStore(db)
	citationsDB := citations.NewDBStore(db)

	// Create the detectors
	var detectors []*citations.Detector
	detectors = append(detectors, citations.GenericDetector)
	abbreviations, err := citationsDB.GetSingleVolReporters(startup)
	if err != nil {
		log.WithError(err).Fatal("Error getting single volume reporters from database")
	}
	for _, abbr := range abbreviations {
		d := citations.NewSingleVolDetector(abbr, abbr)
		detectors = append(detectors, d)
	}
	log.Infof("Prepared generic detector plus %v single-volume detectors", len(detectors)-1)

	log.Info("Getting OCR corrections")
	ocrSubs, err := sourcesDB.GetOCRSubstitutions(startup)
	if err != nil {
		log.WithError(err).Fatal("Error getting OCR substitutions")
	}
	log.Println(ocrSubs)

	log.Info("Getting all treatise/page IDs")
	pageIDs, err := sourcesDB.GetAllTreatisePageIDs(startup)
	if err != nil {
		log.WithError(err).Fatal("Error getting treatise/page IDs")
	}
	log.Infof("Found %v total pages", len(pageIDs))

	pb := progressbar.Default(int64(len(pageIDs)))
	log.Println(pb)

}
