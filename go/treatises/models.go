package treatises

// Page represents a page from a treatise in MOML.
type Page struct {
	DocID    string
	PageID   string
	FullText string
}

// Text returns the full text for a treatise.
func (t *Page) Text() string {
	return t.FullText
}

func (t Page) String() string {
	return t.DocID + "-" + t.PageID
}
