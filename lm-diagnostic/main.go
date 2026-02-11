package main

import (
	"context"
	"log/slog"
	"os"
	"runtime"

	"github.com/lmullen/legal-modernism/go/db"
)

func init() {
	initLogger()
}

func main() {
	slog.Info("starting diagnostics")

	// Report the hostname
	host, err := os.Hostname()
	if err != nil {
		slog.Error("error getting hostname", "error", err)
		os.Exit(1)
	}
	slog.Info("hostname", "host", host)

	// Report CPU cores
	cpus := runtime.NumCPU()
	slog.Info("available CPUs", "cpu_cores", cpus)

	// Test database connectivity
	ctx := context.Background()
	pool, err := db.Connect(ctx)
	if err != nil {
		slog.Error("error connecting to database", "error", err)
		os.Exit(1)
	}
	defer pool.Close()
	slog.Info("successfully connected to database")

	slog.Info("diagnostics complete")
}
