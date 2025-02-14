package db

import (
	"context"
	"errors"
	"fmt"
	"os"
	"time"

	"github.com/jackc/pgx/v4/pgxpool"
)

// Connect returns a pool of connections to the database, which is concurrency
// safe. Uses the pgx interface.
func Connect(ctx context.Context) (*pgxpool.Pool, error) {
	timeout, cancel := context.WithTimeout(ctx, 1*time.Minute)
	defer cancel()

	connstr, err := getConnString()
	if err != nil {
		return nil, err
	}

	db, err := pgxpool.Connect(timeout, connstr)
	if err != nil {
		return nil, fmt.Errorf("error connecting to database: %w", err)
	}

	err = db.Ping(timeout)
	if err != nil {
		return nil, fmt.Errorf("error pinging database: %w", err)
	}

	return db, nil
}

// getConnString returns the DB connection string set as an environment variable
func getConnString() (string, error) {
	connstr, exists := os.LookupEnv("LAW_DBSTR")
	if !exists {
		return "", errors.New("database connection string not set; use the LAW_DBSTR environment variable")
	}
	return connstr, nil
}
