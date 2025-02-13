package main

import (
	"log/slog"
	"os"
)

// If the environment variable reads "debug" set the logging level to DEBUG;
// otherwise use INFO. Emit logs as JSON to stderr.
func initLogger() {
	env := os.Getenv("LAW_DEBUG_LEVEL")
	var level slog.Level
	if env == "debug" {
		level = slog.LevelDebug
	} else {
		level = slog.LevelInfo

	}
	opts := &slog.HandlerOptions{Level: level}
	handler := slog.NewJSONHandler(os.Stderr, opts)
	logger := slog.New(handler)
	slog.SetDefault(logger)
	slog.Debug("set up the logger", "level", level)
}
