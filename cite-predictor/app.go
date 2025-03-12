package main

import (
	"context"
	"errors"
	"log/slog"
	"os"
	"time"

	"github.com/anthropics/anthropic-sdk-go"
	"github.com/anthropics/anthropic-sdk-go/option"
	"github.com/jackc/pgx/v4/pgxpool"
	"github.com/lmullen/legal-modernism/go/db"
	"github.com/lmullen/legal-modernism/go/predictor"
	"github.com/lmullen/legal-modernism/go/sources"
)

// The Config type stores configuration which is read from environment variables.
// - Batch
type Config struct {
	BatchSize    int
	MaxBatches   int
	AnthropicKey string
	PollDelay    time.Duration
}

// The App type shares access to resources.
type App struct {
	Config          Config
	DB              *pgxpool.Pool
	SourcesStore    *sources.PgxStore
	PredictorStore  *predictor.PgxStore
	AnthropicClient *anthropic.Client
}

func NewApp(ctx context.Context) (*App, error) {
	a := App{}

	akey := os.Getenv("ANTHROPIC_DEV_KEY")
	if akey == "" {
		return nil, errors.New("key for Anthropic API not set or empty")
	}

	// Set up configuration
	config := Config{
		BatchSize:    3,
		MaxBatches:   3,
		AnthropicKey: akey,
		PollDelay:    15 * time.Second,
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

	// Initialize the interfaces to the database
	a.SourcesStore = sources.NewPgxStore(a.DB)
	a.PredictorStore = predictor.NewPgxStore(a.DB)

	a.AnthropicClient = anthropic.NewClient(
		option.WithAPIKey(a.Config.AnthropicKey),
	)

	return &a, nil
}

// Shutdown closes shared resources.
func (a *App) Shutdown() {
	slog.Info("closing connection to the database")
	a.DB.Close()
	slog.Info("database connection closed")
}
