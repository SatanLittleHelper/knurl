package auth_test

import (
	"context"
	"errors"
	"testing"

	"github.com/google/uuid"
	"github.com/satanlittlehelper/knurl/backend/internal/auth"
	"golang.org/x/crypto/bcrypt"
)

type mockUserRepo struct {
	createErr error
	foundUser *auth.User
	findErr   error
}

func (m *mockUserRepo) Create(_ context.Context, _ *auth.User) error {
	return m.createErr
}

func (m *mockUserRepo) FindByEmail(_ context.Context, _ string) (*auth.User, error) {
	return m.foundUser, m.findErr
}

const testJWTSecret = "a-secret-key-that-is-at-least-32-chars!"

func TestRegister_Success(t *testing.T) {
	svc := auth.NewService(&mockUserRepo{}, testJWTSecret)
	token, err := svc.Register(context.Background(), "user@example.com", "password123")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if token == "" {
		t.Fatal("expected non-empty token")
	}
}

func TestRegister_ShortPassword(t *testing.T) {
	svc := auth.NewService(&mockUserRepo{}, testJWTSecret)
	_, err := svc.Register(context.Background(), "user@example.com", "abc")
	if err == nil {
		t.Fatal("expected error for short password")
	}
}

func TestRegister_InvalidEmail(t *testing.T) {
	svc := auth.NewService(&mockUserRepo{}, testJWTSecret)
	_, err := svc.Register(context.Background(), "not-an-email", "password123")
	if err == nil {
		t.Fatal("expected error for invalid email")
	}
}

func TestRegister_EmailTaken(t *testing.T) {
	repo := &mockUserRepo{createErr: auth.ErrEmailTaken}
	svc := auth.NewService(repo, testJWTSecret)
	_, err := svc.Register(context.Background(), "user@example.com", "password123")
	if !errors.Is(err, auth.ErrEmailTaken) {
		t.Fatalf("expected ErrEmailTaken, got %v", err)
	}
}

func TestRegister_RepoError(t *testing.T) {
	repo := &mockUserRepo{createErr: errors.New("db error")}
	svc := auth.NewService(repo, testJWTSecret)
	_, err := svc.Register(context.Background(), "user@example.com", "password123")
	if err == nil || errors.Is(err, auth.ErrEmailTaken) {
		t.Fatalf("expected generic error, got %v", err)
	}
}

func TestLogin_Success(t *testing.T) {
	hash, _ := bcrypt.GenerateFromPassword([]byte("password123"), bcrypt.DefaultCost)
	user := &auth.User{ID: uuid.New(), Email: "user@example.com", PasswordHash: string(hash)}
	svc := auth.NewService(&mockUserRepo{foundUser: user}, testJWTSecret)
	token, err := svc.Login(context.Background(), "user@example.com", "password123")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if token == "" {
		t.Fatal("expected non-empty token")
	}
}

func TestLogin_UserNotFound(t *testing.T) {
	repo := &mockUserRepo{findErr: errors.New("record not found")}
	svc := auth.NewService(repo, testJWTSecret)
	_, err := svc.Login(context.Background(), "user@example.com", "password123")
	if !errors.Is(err, auth.ErrInvalidCredentials) {
		t.Fatalf("expected ErrInvalidCredentials, got %v", err)
	}
}

func TestLogin_WrongPassword(t *testing.T) {
	hash, _ := bcrypt.GenerateFromPassword([]byte("correct-password"), bcrypt.DefaultCost)
	user := &auth.User{ID: uuid.New(), Email: "user@example.com", PasswordHash: string(hash)}
	svc := auth.NewService(&mockUserRepo{foundUser: user}, testJWTSecret)
	_, err := svc.Login(context.Background(), "user@example.com", "wrong-password")
	if !errors.Is(err, auth.ErrInvalidCredentials) {
		t.Fatalf("expected ErrInvalidCredentials, got %v", err)
	}
}
