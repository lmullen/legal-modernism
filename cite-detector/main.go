package main

import (
	"context"
	"time"

	"github.com/lmullen/legal-modernism/go/citations"
	"github.com/lmullen/legal-modernism/go/db"
	"github.com/lmullen/legal-modernism/go/treatises"
	log "github.com/sirupsen/logrus"
)

func main() {

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()

	db, err := db.Connect(ctx)
	if err != nil {
		log.WithError(err).Fatal("Error connecting to database")
	}
	defer db.Close()

	citeRepo := citations.NewPgxRepo(db)
	genericDetector := citations.NewDetector("Generic", `[\p{L}\s\.]{4,15}?`)

	// Query for all the treatise pages full text
	queryPages := `SELECT psmid, pageid, ocrtext FROM moml.page_ocrtext LIMIT 1000;`

	rows, err := db.Query(context.TODO(), queryPages)
	if err != nil {
		log.WithError(err).Fatal("Error querying database for treatise pages")
	}
	defer rows.Close()
	for rows.Next() {
		page := &treatises.Page{}
		err = rows.Scan(&page.DocID, &page.PageID, &page.FullText)
		if err != nil {
			log.WithError(err).Error("Error scanning row of treatise page")
		}

		log.WithField("page", page).Info("Detecting citations in treatise page")
		citations := genericDetector.Detect(page)
		for _, cite := range citations {
			err := citeRepo.Save(context.TODO(), cite)
			if err != nil {
				log.WithError(err).Error("Error saving citation to database")
			}
		}

	}

}
