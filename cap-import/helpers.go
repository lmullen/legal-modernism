package main

import (
	"database/sql"
	"fmt"
	"strconv"
	"time"
)

const dateLayout = "2006-01-02"

func parseDate(raw string) sql.NullTime {
	date := sql.NullTime{}
	time, err := time.Parse(dateLayout, raw)
	if err != nil {
		return date
	}
	date.Scan(time)
	return date
}

func parseInt(raw string) sql.NullInt32 {
	out := sql.NullInt32{}
	parsed, err := strconv.Atoi(raw)
	if err != nil {
		return out
	}
	out.Scan(parsed)
	return out
}

// consoleTimeFormat sets a simple format for the pretty logs without colors
func consoleTimeFormat(i interface{}) string {
	ts := i.(string)
	t, err := time.Parse(time.RFC3339, ts)
	if err != nil {
		return fmt.Sprint(i)
	}
	return t.Format(time.Kitchen)
}
