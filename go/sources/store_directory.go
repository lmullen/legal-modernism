package sources

import (
	"context"
	"fmt"
	"os"
	"path"
)

// DirectoryStore is a datastore for sources containing plain text files in a
// directory. The filenames will be used as the identifiers.
type DirectoryStore struct {
	Path string
}

// NewDirectoryStore creates a new DirectoryStore
func NewDirectoryStore(path string) (*DirectoryStore, error) {
	info, err := os.Stat(path)

	if os.IsNotExist(err) {
		return nil, fmt.Errorf("Directory %s does not exist: %w", path, err)
	}

	if !info.IsDir() {
		return nil, fmt.Errorf("Path %s is not a directory", path)
	}

	if err != nil {
		return nil, fmt.Errorf("Cannot create store from path %s: %w", path, err)
	}

	store := &DirectoryStore{
		Path: path,
	}

	return store, nil
}

// GetDocByID takes a file name and returns a document representation by reading
// the file contents from the directory.
func (ds *DirectoryStore) GetDocByID(ctx context.Context, id string) (*Doc, error) {
	filepath := path.Join(ds.Path, id)
	contents, err := os.ReadFile(filepath)
	if err != nil {
		return nil, fmt.Errorf("Failed to read file %s from directory: %w", filepath, err)
	}
	doc := NewDoc(id, string(contents))
	return doc, nil
}
