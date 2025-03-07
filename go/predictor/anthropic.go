package predictor

import (
	"context"

	"github.com/anthropics/anthropic-sdk-go"
)

// SendAnthropicBatch creates and submits a batch of requests, one for each page in the batch
func (b *Batch) SendAnthropicBatch(ctx context.Context, client anthropic.Client) error {
	// Create a request for each item in the batch
	reqs := make([]anthropic.BetaMessageBatchNewParamsRequest, b.NumRequests())
	for i := range b.NumRequests() {
		reqs[i] = b.Requests[i].CreateAnthropicMessage()
	}

	// Put the requests in the batch and send it
	msgBatch, err := client.Beta.Messages.Batches.New(ctx, anthropic.BetaMessageBatchNewParams{
		Requests: anthropic.F(reqs),
		Betas:    anthropic.F([]anthropic.AnthropicBeta{anthropic.AnthropicBetaMessageBatches2024_09_24}),
	})
	if err != nil {
		return err
	}

	b.AnthropicID.String = msgBatch.ID
	b.AnthropicID.Valid = true

	b.AnthropicBatch = msgBatch

	return nil
}

// CreateAnthropicRequest creates a message tied to a specific treatise page.
// This is intended to be used in a batch.
func (r *Request) CreateAnthropicMessage() anthropic.BetaMessageBatchNewParamsRequest {

	// TODO: Replace with a prompt that does real work.
	prompt := "Write a limerick on a subject of your choice."

	msg := anthropic.BetaMessageBatchNewParamsRequest{
		CustomID: anthropic.F(r.ID.String()),
		Params: anthropic.F(anthropic.BetaMessageBatchNewParamsRequestsParams{
			MaxTokens: anthropic.F(int64(1024)),
			Messages: anthropic.F([]anthropic.BetaMessageParam{
				{
					Content: anthropic.F([]anthropic.BetaContentBlockParamUnion{
						anthropic.BetaTextBlockParam{
							Text: anthropic.F(prompt),
							Type: anthropic.F(anthropic.BetaTextBlockParamTypeText),
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
					Role: anthropic.F(anthropic.BetaMessageParamRoleUser),
				},
			}),
			Model: anthropic.F(anthropic.ModelClaude3_7SonnetLatest),
		}),
	}

	return msg
}
