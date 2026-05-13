package api_test

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"github.com/satanlittlehelper/knurl/backend/internal/api"
)

func TestRespond_SetsStatusAndBody(t *testing.T) {
	w := httptest.NewRecorder()
	api.Respond(w, http.StatusOK, map[string]string{"key": "value"})

	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", w.Code)
	}
	if ct := w.Header().Get("Content-Type"); ct != "application/json" {
		t.Fatalf("expected application/json, got %s", ct)
	}
	body := strings.TrimSpace(w.Body.String())
	if body != `{"key":"value"}` {
		t.Fatalf("unexpected body: %s", body)
	}
}

func TestRespond_Created(t *testing.T) {
	w := httptest.NewRecorder()
	api.Respond(w, http.StatusCreated, map[string]string{"id": "1"})

	if w.Code != http.StatusCreated {
		t.Fatalf("expected 201, got %d", w.Code)
	}
}

func TestError_SetsStatusAndErrorBody(t *testing.T) {
	w := httptest.NewRecorder()
	api.Error(w, http.StatusBadRequest, "bad request")

	if w.Code != http.StatusBadRequest {
		t.Fatalf("expected 400, got %d", w.Code)
	}
	if ct := w.Header().Get("Content-Type"); ct != "application/json" {
		t.Fatalf("expected application/json, got %s", ct)
	}
	body := strings.TrimSpace(w.Body.String())
	if body != `{"error":"bad request"}` {
		t.Fatalf("unexpected body: %s", body)
	}
}

func TestNoContent_Returns204WithEmptyBody(t *testing.T) {
	w := httptest.NewRecorder()
	api.NoContent(w)

	if w.Code != http.StatusNoContent {
		t.Fatalf("expected 204, got %d", w.Code)
	}
	if w.Body.Len() != 0 {
		t.Fatalf("expected empty body, got: %s", w.Body.String())
	}
}
