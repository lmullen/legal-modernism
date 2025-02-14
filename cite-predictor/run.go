package main

import (
	"context"
	"fmt"
)

// Run does the primary work of the application
func (a *App) Run(ctx context.Context) error {
	pages, err := a.Sources.GetBatchOfUnprocessedPages(ctx, a.Config.BatchSize)
	if err != nil {
		return err
	}
	for _, p := range pages {
		fmt.Println(p)
	}
	return nil
}
