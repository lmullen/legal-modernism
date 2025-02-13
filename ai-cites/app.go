package main

import (
	"context"

	"github.com/jackc/pgx"
)

// The Config type stores configuration which is read from environment variables.
type Config struct {
}

// The App type shares access to resources.
type App struct {
	Config Config
	DB     *pgx.ConnPool
}

func NewApp(ctx context.Context) (*App, error) {
	a := App{}
	config := Config{}
	a.Config = config
	return &a, nil
}

func (a *App) Run(ctx context.Context) error {
	return nil
}

// Shutdown closes shared resources.
func (a *App) Shutdown() {
}
