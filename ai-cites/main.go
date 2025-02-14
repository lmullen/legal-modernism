// This command looks for citations from Making of Modern Law Treatises to the
// Caselaw Access Project cases using Claude.
package main

import (
	"context"
	"log/slog"
	"os"
	"os/signal"
	"syscall"
	"time"
)

func init() {
	initLogger()
}

func main() {

	// Create a context and listen for signals to gracefully shutdown the application
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()

	var app *App

	// Set up signal handling after app creation
	quit := make(chan os.Signal, 1)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM, syscall.SIGHUP)
	defer signal.Stop(quit)

	// Listen for shutdown signals in a go-routine
	go func() {
		select {
		case sig := <-quit:
			slog.Info("shutting down in response to signal", "signal", sig.String())

			// Create a timeout context for shutdown
			shutdownCtx, shutdownCancel := context.WithTimeout(context.Background(), 30*time.Second)
			defer shutdownCancel()

			done := make(chan struct{})
			go func() {
				app.Shutdown()
				close(done)
			}()

			select {
			case <-done:
			case <-shutdownCtx.Done():
				slog.Error("shutdown timed out, forcing exit")
				os.Exit(1)
			}

			cancel()
		case <-ctx.Done():
			slog.Debug("main context cancelled, shutting down signal handler")
		}
	}()

	// Create the app first
	slog.Info("setting up resources")
	app, err := NewApp(ctx)
	if err != nil {
		slog.Error("error setting up resources", "error", err)
		cancel()
		os.Exit(1)
	}
	defer app.Shutdown()

	slog.Info("running the app")
	err = app.Run(ctx)
	if err != nil {
		slog.Error("error running app", "error", err)
		cancel()
		os.Exit(1)
	}

}
