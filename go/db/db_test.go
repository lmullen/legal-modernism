package db

import (
	"os"
	"testing"
)

func Test_EmptyConnString(t *testing.T) {
	os.Unsetenv("MOML_DBSTR")
	_, err := getConnString()
	if err == nil {
		t.Error("Did not get an error when DB connection string was not set")
	}
}

func Test_SetConnString(t *testing.T) {
	connstr := "postgres://user:pass@localhost:5432/cchc"
	envvar := "MOML_DBSTR"
	os.Setenv(envvar, connstr)
	got, err := getConnString()
	if err != nil {
		t.Error("Got an error when connection string was set: ", err)
	}
	if got != connstr {
		t.Error("Connection string does not match environment variable")
	}
}
