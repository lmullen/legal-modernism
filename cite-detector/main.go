package main

import (
	"context"
	"os"
	"os/signal"
	"runtime"
	"syscall"

	"github.com/gammazero/workerpool"
	"github.com/lmullen/legal-modernism/go/citations"
	"github.com/lmullen/legal-modernism/go/db"
	"github.com/lmullen/legal-modernism/go/sources"
	"github.com/schollz/progressbar/v3"
	log "github.com/sirupsen/logrus"
)

func main() {
	log.Info("Starting the citation detector")

	// Create the worker pool
	cpuMax := runtime.NumCPU()
	cpu := cpuMax - 2
	if cpu < 1 {
		cpu = 1
	}
	log.Infof("Found %v CPUs available, using %v", cpuMax, cpu)
	wp := workerpool.New(cpu)

	// Create a context and listen for signals to gracefully shutdown the application
	ctx, cancel := context.WithCancel(context.Background())
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	// Clean up function that will be called at program end no matter what
	defer func() {
		signal.Stop(quit)
		cancel()
	}()
	// Listen for shutdown signals in a go routine and cancel context then
	go func() {
		select {
		case <-quit:
			log.Info("Quitting because shutdown signal received")
			cancel()
			// wp.Stop()
		case <-ctx.Done():
		}
	}()

	log.Info("Connecting to database")
	db, err := db.Connect(ctx)
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
	abbreviations, err := citationsDB.GetSingleVolReporters(ctx)
	if err != nil {
		log.WithError(err).Fatal("Error getting single volume reporters from database")
	}
	for _, abbr := range abbreviations {
		d := citations.NewSingleVolDetector(abbr, abbr)
		detectors = append(detectors, d)
	}
	log.Infof("Prepared generic detector plus %v single-volume detectors", len(detectors)-1)

	log.Info("Getting OCR corrections")
	ocrSubs, err := sourcesDB.GetOCRSubstitutions(ctx)
	if err != nil {
		log.WithError(err).Fatal("Error getting OCR substitutions")
	}

	log.Info("Getting all treatise/page IDs")
	pageIDs, err := sourcesDB.GetAllTreatisePageIDs(ctx)
	if err != nil {
		log.WithError(err).Fatal("Error getting treatise/page IDs")
	}
	log.Infof("Found %v total pages", len(pageIDs))

	pb := progressbar.Default(int64(len(pageIDs)))

	log.Info("Detecting citations on the treatise pages")

	for _, pageID := range pageIDs {
		select {
		case <-ctx.Done():
			return
		default:
			id := pageID
			wp.Submit(func() {
				select {
				case <-ctx.Done():
					return
				default:
					// Do the actual work for each treatise page
					page, err := sourcesDB.GetTreatisePage(ctx, id.TreatiseID, id.PageID)
					if err != nil {
						log.
							WithError(err).
							WithField("treatise id", id.TreatiseID).
							WithField("page id", id.PageID).
							Error("Error fetching page from database")
					}
					page.CorrectOCR(ocrSubs)
					for _, detector := range detectors {
						citations := detector.Detect(page)
						for _, cite := range citations {
							err = citationsDB.SaveCitation(ctx, cite)
							if err != nil {
								log.WithError(err).WithField("citation", cite).Error("Error saving citation")
							}
						}
					}
				}
				pb.Add(1)
			})
		}
	}

	wp.StopWait()
	log.Info("Done detecting citations")

}
