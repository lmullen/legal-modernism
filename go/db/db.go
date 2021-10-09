package db

import (
	"context"
	"errors"
	"fmt"
	"os"

	"github.com/jackc/pgx/v4/pgxpool"
)

// Connect returns a pool of connection to the database, which is conncurrency
// safe. Uses the pgx interface.
func Connect(ctx context.Context) (*pgxpool.Pool, error) {
	connstr, err := getConnString()
	if err != nil {
		return nil, err
	}

	db, err := pgxpool.Connect(ctx, connstr)
	if err != nil {
		return nil, fmt.Errorf("Error connecting to database: %w", err)
	}

	err = db.Ping(ctx)
	if err != nil {
		return nil, fmt.Errorf("Error pinging database: %w", err)
	}

	return db, nil
}

// getConnString returns the DB connection string set as an environment variable
func getConnString() (string, error) {
	connstr, exists := os.LookupEnv("MOML_DBSTR")
	if !exists {
		return "", errors.New("Database connection string not set; use the MOML_DBSTR environment variable")
	}
	return connstr, nil
}
