// This command looks for citations from Making of Modern Law Treatises to the
// Caselaw Access Project cases using Claude.
package main

import (
	"context"
	"log/slog"
	"os"
	"os/signal"
	"sync"
	"syscall"
)

func init() {
	initLogger()
}

func main() {
	var app *App

	// Create a context that can cancel all in progress work
	ctx, cancel := context.WithCancel(context.Background())

	// Listen for signals to shutdown the application gracefully
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM, syscall.SIGHUP)
	defer signal.Stop(quit)

	// Clean up function that will be called at program end no matter what.
	defer func() {
		slog.Debug("running deferred shutdown function")
		cancel()
		app.Shutdown()
	}()

	// Listen for shutdown signals in a go routine and cancel context then
	go func() {
		select {
		case sig := <-quit: // first signal, cancel context
			slog.Info("shutdown signal received, shutting down cleanly", "signal", sig.String())
			cancel()
		case <-ctx.Done():
			slog.Debug("main context done")
		}
		sig := <-quit // second signal, hard exit
		slog.Warn("second shutdown signal received, shutting down immediately", "signal", sig.String())
		os.Exit(2)
	}()

	// Create the app first
	slog.Debug("setting up resources")
	app, err := NewApp(ctx)
	if err != nil {
		slog.Error("error setting up resources", "error", err)
		os.Exit(1)
	}

	slog.Debug("running the app")

	var wg sync.WaitGroup

	// Send batches to Claude
	// wg.Add(1)
	// go func() {
	// 	err := app.SendBatches(ctx)
	// 	if err != nil {
	// 		slog.Error("error in sending subprocess", "error", err)
	// 		cancel()
	// 		os.Exit(2)
	// 	}
	// 	wg.Done()
	// }()

	wg.Add(1)
	go func() {
		err := app.GetBatches(ctx)
		if err != nil {
			slog.Error("error in retrieving subprocess", "error", err)
			cancel()
			os.Exit(2)
		}
		wg.Done()
	}()

	wg.Wait()

}
