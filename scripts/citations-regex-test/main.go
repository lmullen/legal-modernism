package main

import (
	"context"
	"fmt"
	"log"

	"github.com/lmullen/legal-modernism/go/citations"
	"github.com/lmullen/legal-modernism/go/sources"
)

func main() {
	dir, err := sources.NewDirectoryStore("data")
	if err != nil {
		log.Fatal(err)
	}

	doc, err := dir.GetDocByID(context.TODO(), "pretend-document.txt")
	if err != nil {
		log.Fatal(err)
	}

	cites := citations.GenericDetector.Detect(doc)
	for i, cite := range cites {
		fmt.Printf("%4v: %v\n", i, cite)
	}
}
