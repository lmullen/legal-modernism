// This script finds the citations for a set of pages from a certain
// treatise.
package main

import (
	"context"
	"encoding/csv"
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"time"

	"github.com/lmullen/legal-modernism/go/citations"
	"github.com/lmullen/legal-modernism/go/db"
	"github.com/lmullen/legal-modernism/go/sources"
	log "github.com/sirupsen/logrus"
)

func main() {

	// http://link.galegroup.com/apps/doc/F0103695531/MOML?sid=dhxml
	// treatiseID := "19004617901"
	// pagesID := pages(178, 10)

	// http://link.galegroup.com/apps/doc/F0105343875/MOML?sid=dhxml
	// treatiseID := "19006691600"
	// pagesID := pages(600, 10)

	// http://link.galegroup.com/apps/doc/F0105343875/MOML?sid=dhxml
	treatiseID := "20002902000"
	pagesID := pages(325, 10)

	outPath := filepath.Join("out/", treatiseID+"-citations.csv")
	outFile, err := os.Create(outPath)
	if err != nil {
		log.WithError(err).Fatal("Error opening output file")
	}
	defer outFile.Close()
	writer := csv.NewWriter(outFile)
	defer writer.Flush()

	header := []string{
		"treatise",
		"page",
		"cite",
		"volume",
		"reporter",
		"page",
		"raw",
	}
	err = writer.Write(header)
	if err != nil {
		log.WithError(err).Error("Error writing to csv")
	}

	ctx := context.Background()
	timeout, cancel := context.WithTimeout(ctx, 15*time.Second)
	defer cancel()
	db, err := db.Connect(timeout)
	if err != nil {
		log.WithError(err).Fatal("Error connecting to database")
	}
	defer db.Close()
	store := sources.NewPgxStore(db)

	detector := citations.GenericDetector
	subs, err := sources.OCRSubstitutionsFromCSV("data/ocr-errors.csv")
	if err != nil {
		log.WithError(err).Fatal("Error getting OCR substitutions")
	}

	for _, pageID := range pagesID {
		page, err := store.GetTreatisePage(ctx, treatiseID, pageID)
		if err != nil {
			log.WithError(err).Fatal("Error getting page from database")
		}
		page.CorrectOCR(subs)
		citations := detector.Detect(page)

		for _, cite := range citations {
			record := []string{
				treatiseID,
				pageID,
				cite.CleanCite(),
				strconv.Itoa(cite.Volume),
				cite.ReporterAbbr,
				strconv.Itoa(cite.Page),
				cite.Raw,
			}
			err = writer.Write(record)
			if err != nil {
				log.WithError(err).Error("Error writing record to CSV")
			}
		}
		writer.Flush()
	}

}

func pages(start int, length int) []string {
	var out []string
	for i := 0; i < length; i++ {
		num := start + i
		pageID := fmt.Sprintf("%04d0", num)
		out = append(out, pageID)
	}
	return out
}
