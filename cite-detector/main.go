package main

import (
	"context"
	"log/slog"
	"os"
	"os/signal"
	"runtime"
	"syscall"

	"github.com/gammazero/workerpool"
	"github.com/lmullen/legal-modernism/go/citations"
	"github.com/lmullen/legal-modernism/go/db"
	"github.com/lmullen/legal-modernism/go/sources"
	"github.com/schollz/progressbar/v3"
)

func main() {
	slog.Info("Starting the citation detector")

	// Create the worker pool
	cpuMax := runtime.NumCPU()
	cpu := cpuMax - 2
	if cpu < 1 {
		cpu = 1
	}
	slog.Info("CPUs", "available", cpuMax, "using", cpu)
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
			slog.Info("Quitting because shutdown signal received")
			cancel()
			// wp.Stop()
		case <-ctx.Done():
		}
	}()

	slog.Info("Connecting to database")
	db, err := db.Connect(ctx)
	if err != nil {
		slog.Error("could not connect to database", "error", err)
		os.Exit(1)
	}
	defer db.Close()
	slog.Info("connected to the database")

	// Create the repositories
	sourcesDB := sources.NewPgxStore(db)
	citationsDB := citations.NewDBStore(db)

	// Create the detectors
	var detectors []*citations.Detector
	detectors = append(detectors, citations.GenericDetector)
	abbreviations, err := citationsDB.GetSingleVolReporters(ctx)
	if err != nil {
		slog.Error("could not get single volume reporters from database", "error", err)
		os.Exit(1)
	}
	for _, abbr := range abbreviations {
		d := citations.NewSingleVolDetector(abbr, abbr)
		detectors = append(detectors, d)
	}
	slog.Info("prepared generic detector and single volume detector", "num_detectors", len(detectors))

	slog.Info("Getting OCR corrections")
	ocrSubs, err := sourcesDB.GetOCRSubstitutions(ctx)
	if err != nil {
		slog.Error("error getting OCR substitutions", "error", err)
	}

	slog.Info("getting all treatise/page IDs")
	pageIDs, err := sourcesDB.GetAllTreatisePageIDs(ctx)
	if err != nil {
		slog.Error("error getting treatise/page IDs", "error", err)
	}
	slog.Info("found pages", "num_pages", len(pageIDs))

	pb := progressbar.Default(int64(len(pageIDs)))

	slog.Info("detecting citations on the treatise pages")

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
						slog.Error("could not fetch page from database", "treatise_id", id.TreatiseID, "page_id", id.PageID, "error", err)
					}
					page.CorrectOCR(ocrSubs)
					for _, detector := range detectors {
						citations := detector.Detect(page)
						for _, cite := range citations {
							err = citationsDB.SaveCitation(ctx, cite)
							if err != nil {
								slog.Error("could not save citation", "citation", cite, "error", err)
							}
						}
					}
				}
				pb.Add(1)
			})
		}
	}

	wp.StopWait()
	slog.Info("done detecting citations")

}
