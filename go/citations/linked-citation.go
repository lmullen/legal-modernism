package citations

import "github.com/google/uuid"

type LinkedCitation struct {
	ID           uuid.UUID
	MOMLTreatise string
	MOMLPage     string
	Raw          string
	Volume       int
	ReporterAbbr string
	Page         int
}
