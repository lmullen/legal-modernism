package main

import (
	"context"
	"os"
	"os/signal"
	"syscall"

	"github.com/google/uuid"
	"github.com/lmullen/legal-modernism/go/citations"
	"github.com/lmullen/legal-modernism/go/db"
	log "github.com/sirupsen/logrus"
)

func main() {
	log.Info("Starting the citation linker")

	// Create the worker pool
	// cpuMax := runtime.NumCPU()
	// cpu := cpuMax - 2
	// if cpu < 1 {
	// 	cpu = 1
	// }
	// log.Infof("Found %v CPUs available, using %v", cpuMax, cpu)
	// wp := workerpool.New(cpu)

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

	log.Info("Getting citation: 621d0066-dc81-4858-a857-2e4ddc42997e")

	citationsDB := citations.NewDBStore(db)

	id := uuid.MustParse("621d0066-dc81-4858-a857-2e4ddc42997e")
	cite, err := citationsDB.GetLinkedCitationByID(ctx, id)

	if err != nil {
		log.Fatal(err)
	}
	log.Info(cite)

}
