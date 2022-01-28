package main

import (
	"fmt"
	"log"

	"github.com/lmullen/legal-modernism/go/sources"
)

func main() {
	input := `This is a document demonstrating OCR error correction.
	Some sample errors are Tcx, Cnm, Tcn, and Dalk.
	`
	doc := sources.NewDoc("demo", input)

	subs, err := sources.OCRSubstitutionsFromCSV("data/ocr-errors.csv")
	if err != nil {
		log.Fatal(err)
	}

	fmt.Println("INPUT:")
	fmt.Println(doc.Text())
	fmt.Println()
	fmt.Println("OUTPUT:")
	doc.CorrectOCR(subs)
	fmt.Println(doc.Text())
}
