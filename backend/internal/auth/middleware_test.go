package auth_test

import (
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/satanlittlehelper/knurl/backend/internal/auth"
)

const testSecret = "test-secret"

func makeToken(t *testing.T, subject string, secret string, valid bool) string {
	t.Helper()
	claims := jwt.RegisteredClaims{
		Subject:   subject,
		ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Hour)),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signingKey := []byte(secret)
	if !valid {
		signingKey = []byte("wrong-secret")
	}
	signed, err := token.SignedString(signingKey)
	if err != nil {
		t.Fatalf("failed to sign token: %v", err)
	}
	return signed
}

func assertJSONUnauthorized(t *testing.T, w *httptest.ResponseRecorder) {
	t.Helper()
	if w.Code != http.StatusUnauthorized {
		t.Fatalf("expected 401, got %d", w.Code)
	}
	if ct := w.Header().Get("Content-Type"); ct != "application/json" {
		t.Fatalf("expected Content-Type application/json, got %s", ct)
	}
	body := strings.TrimSpace(w.Body.String())
	if body != `{"error":"unauthorized"}` {
		t.Fatalf("unexpected body: %s", body)
	}
}

func nextHandler() http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
	})
}

func TestMiddleware_MissingAuthorizationHeader(t *testing.T) {
	handler := auth.Middleware(testSecret)(nextHandler())
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	w := httptest.NewRecorder()
	handler.ServeHTTP(w, req)
	assertJSONUnauthorized(t, w)
}

func TestMiddleware_NoBearerPrefix(t *testing.T) {
	handler := auth.Middleware(testSecret)(nextHandler())
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.Header.Set("Authorization", "Basic abc123")
	w := httptest.NewRecorder()
	handler.ServeHTTP(w, req)
	assertJSONUnauthorized(t, w)
}

func TestMiddleware_InvalidToken(t *testing.T) {
	handler := auth.Middleware(testSecret)(nextHandler())
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.Header.Set("Authorization", "Bearer "+makeToken(t, "user-id", testSecret, false))
	w := httptest.NewRecorder()
	handler.ServeHTTP(w, req)
	assertJSONUnauthorized(t, w)
}

func TestMiddleware_SubjectNotUUID(t *testing.T) {
	claims := jwt.RegisteredClaims{
		Subject:   "not-a-uuid",
		ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Hour)),
	}
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)
	signed, _ := token.SignedString([]byte(testSecret))

	handler := auth.Middleware(testSecret)(nextHandler())
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.Header.Set("Authorization", "Bearer "+signed)
	w := httptest.NewRecorder()
	handler.ServeHTTP(w, req)
	assertJSONUnauthorized(t, w)
}

func TestMiddleware_ValidToken_PassesThrough(t *testing.T) {
	userID := "550e8400-e29b-41d4-a716-446655440000"
	handler := auth.Middleware(testSecret)(nextHandler())
	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.Header.Set("Authorization", "Bearer "+makeToken(t, userID, testSecret, true))
	w := httptest.NewRecorder()
	handler.ServeHTTP(w, req)
	if w.Code != http.StatusOK {
		t.Fatalf("expected 200, got %d", w.Code)
	}
}
