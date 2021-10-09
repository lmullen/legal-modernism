package main

// Document is a uniquely identified document with full text.
type Document interface {
	ID() string
	Text() string
}

// Treatise represents a treatise document from MOML.
type Treatise struct {
	id   string
	text string
}

// ID returns the unique ID for the treatise.
func (t *Treatise) ID() string {
	return t.id
}

// Text returns the full text for a treatise.
func (t *Treatise) Text() string {
	return t.text
}

func (t Treatise) String() string {
	return t.id
}
