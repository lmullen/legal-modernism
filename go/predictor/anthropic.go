package predictor

import (
	"context"

	"github.com/anthropics/anthropic-sdk-go"
)

// SendBatchToAnthropic creates and submits a batch of requests, one for each page in the batch
func (b *Batch) SendBatchToAnthropic(ctx context.Context, client anthropic.Client) error {
	// Create a request for each item in the batch
	reqs := make([]anthropic.MessageBatchNewParamsRequest, b.NumRequests())
	for i := range b.NumRequests() {
		reqs[i] = b.Requests[i].CreateAnthropicMessage()
	}

	// Put the requests in the batch and send it
	msgBatch, err := client.Messages.Batches.New(ctx, anthropic.MessageBatchNewParams{
		Requests: anthropic.F(reqs),
	})
	if err != nil {
		return err
	}

	// Now we know the Anthropic batch ID
	b.AnthropicID.String = msgBatch.ID
	b.AnthropicID.Valid = true

	b.AnthropicBatch = msgBatch

	// Update batch status
	b.Status = "sent"
	for _, r := range b.Requests {
		r.Status = "sent"
	}

	return nil
}

// CreateAnthropicRequest creates a message tied to a specific treatise page.
// This is intended to be used in a batch.
func (r *Request) CreateAnthropicMessage() anthropic.MessageBatchNewParamsRequest {

	// TODO: Replace with a prompt that does real work.
	prompt := "Write a limerick on a subject of your choice."

	msg := anthropic.MessageBatchNewParamsRequest{
		CustomID: anthropic.F(r.ID.String()),
		Params: anthropic.F(anthropic.MessageNewParams{
			MaxTokens: anthropic.F(int64(1024)),
			Messages: anthropic.F([]anthropic.MessageParam{
				{
					Content: anthropic.F([]anthropic.ContentBlockParamUnion{
						anthropic.TextBlockParam{
							Text: anthropic.F(prompt),
							Type: anthropic.F(anthropic.TextBlockParamTypeText),
							// CacheControl: anthropic.F(anthropic.BetaCacheControlEphemeralParam{
							// 	Type: anthropic.F(anthropic.BetaCacheControlEphemeralTypeEphemeral),
							// }),
							// Citations: anthropic.F([]anthropic.BetaTextCitationParamUnion{
							// 	anthropic.BetaCitationCharLocationParam{
							// 		CitedText:      anthropic.F("cited_text"),
							// 		DocumentIndex:  anthropic.F(int64(0)),
							// 		DocumentTitle:  anthropic.F("x"),
							// 		EndCharIndex:   anthropic.F(int64(0)),
							// 		StartCharIndex: anthropic.F(int64(0)),
							// 		Type:           anthropic.F(anthropic.BetaCitationCharLocationParamTypeCharLocation),
							// 	},
							// }),
						},
					}),
					Role: anthropic.F(anthropic.MessageParamRoleUser),
				},
			}),
			Model: anthropic.F(anthropic.ModelClaude3_7SonnetLatest),
		}),
	}

	return msg
}
