// This package deals with making requests to the AI API.
package predictor

import (
	"database/sql"
	"encoding/json"
	"time"

	"github.com/anthropics/anthropic-sdk-go"
	"github.com/google/uuid"
	"github.com/lmullen/legal-modernism/go/sources"
)

// A Batch is a set of requests to the API.
type Batch struct {
	ID             uuid.UUID
	AnthropicID    sql.NullString
	CreatedAt      time.Time
	LastChecked    time.Time
	Status         string
	Result         json.RawMessage
	Requests       []*Request
	AnthropicBatch *anthropic.MessageBatch
	ItemResults    []*ItemResult
}

// String returns the BatchID
func (b *Batch) String() string {
	return b.ID.String()
}

func (b *Batch) Anthropic() *string {
	if b.AnthropicID.Valid {
		return &b.AnthropicID.String
	}
	return nil
}

// LogID returns a slice of keys and values to be used in structured logging.
//
// For example: slog.Info("logging batch", b.LogID()...)
//
// Pass in additional keys and values to also log them.
//
// For example: slog.Info("error in batch", b.LogID("error", err)...)
func (b *Batch) LogID(args ...any) []any {
	return append([]any{"batch_id", b.ID, "anthropic_id", b.Anthropic()}, args...)
}

// NumRequests returns the number of requests in a batch
func (b *Batch) NumRequests() int {
	return len(b.Requests)
}

// NewBatch creates a batch object with the data to be sent to the AI API
func NewBatch(pages []*sources.TreatisePage, purpose string) *Batch {
	b := Batch{}
	b.ID = uuid.New()
	t := time.Now()
	b.CreatedAt = t
	b.LastChecked = t
	b.Status = "recorded"

	// Make a request for each page passed in
	requests := make([]*Request, 0, len(pages))
	var req *Request
	for _, p := range pages {
		req = NewRequest(p, b.ID, purpose)
		requests = append(requests, req)
	}
	b.Requests = requests

	return &b
}

// A request is in an individual request to the API
type Request struct {
	ID      uuid.UUID
	BatchID uuid.UUID
	Purpose string
	Status  string
	Result  json.RawMessage
	Page    *sources.TreatisePage
}

// Get the PsmID (that is, the volume ID from the treatise) from the page
func (r *Request) PsmID() string {
	return r.Page.TreatiseID
}

// Get the PageID from the page
func (r *Request) PageID() string {
	return r.Page.PageID
}

func NewRequest(page *sources.TreatisePage, batch uuid.UUID, purpose string) *Request {
	r := Request{}
	r.ID = uuid.New()
	r.BatchID = batch
	r.Purpose = purpose
	r.Status = "recorded"
	r.Page = page
	return &r
}

type ItemResult struct {
	ID     uuid.UUID
	Status string
	Result json.RawMessage
}
