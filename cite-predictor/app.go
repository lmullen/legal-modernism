package main

import (
	"context"
	"log/slog"

	"github.com/jackc/pgx/v4/pgxpool"
	"github.com/lmullen/legal-modernism/go/db"
)

// The Config type stores configuration which is read from environment variables.
type Config struct {
	BatchSize int
}

// The App type shares access to resources.
type App struct {
	Config Config
	DB     *pgxpool.Pool
}

func NewApp(ctx context.Context) (*App, error) {
	a := App{}

	// Set up configuration
	config := Config{
		BatchSize: 10,
	}
	a.Config = config

	// Connect to the database
	slog.Info("connecting to the database")
	db, err := db.Connect(ctx)
	if err != nil {
		return nil, err
	}
	a.DB = db
	slog.Info("connected succesfully to the database")

	return &a, nil
}

func (a *App) Run(ctx context.Context) error {
	return nil
}

// Shutdown closes shared resources.
func (a *App) Shutdown() {
	slog.Info("closing connection to the database")
	a.DB.Close()
	slog.Info("database connection closed")
}
