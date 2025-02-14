// This command looks for citations from Making of Modern Law Treatises to the
// Caselaw Access Project cases using Claude.
package main

import (
	"context"
	"log/slog"
	"os"
	"os/signal"
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
		case sig := <-quit:
			slog.Info("shutdown signal received", "signal", sig.String())
			cancel()
		case <-ctx.Done():
			slog.Debug("main context done")
		}
	}()

	// Create the app first
	slog.Info("setting up resources")
	app, err := NewApp(ctx)
	if err != nil {
		slog.Error("error setting up resources", "error", err)
		os.Exit(1)
	}

	slog.Info("running the app")
	err = app.Run(ctx)
	if err != nil {
		slog.Error("error running app", "error", err)
		os.Exit(2)
	}

}
