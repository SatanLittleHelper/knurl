package sessions_test

import (
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/satanlittlehelper/knurl/backend/internal/sessions"
)

type mockSessionRepo struct {
	listResult []sessions.WorkoutSession
	err        error
}

func (m *mockSessionRepo) List(_ uuid.UUID) ([]sessions.WorkoutSession, error) {
	return m.listResult, m.err
}
func (m *mockSessionRepo) Create(sess *sessions.WorkoutSession) error { return m.err }
func (m *mockSessionRepo) Finish(_, _ uuid.UUID, _ time.Time) error   { return m.err }
func (m *mockSessionRepo) Delete(_, _ uuid.UUID) error                 { return m.err }

func TestList_Success(t *testing.T) {
	userID := uuid.New()
	want := []sessions.WorkoutSession{{UserID: userID, StartedAt: time.Now()}}
	svc := sessions.NewService(&mockSessionRepo{listResult: want})
	got, err := svc.List(userID)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(got) != 1 {
		t.Fatalf("expected 1 session, got %d", len(got))
	}
}

func TestList_RepoError(t *testing.T) {
	svc := sessions.NewService(&mockSessionRepo{err: errors.New("db error")})
	_, err := svc.List(uuid.New())
	if err == nil {
		t.Fatal("expected error")
	}
}

func TestCreate_Success_UserIDAssigned(t *testing.T) {
	userID := uuid.New()
	svc := sessions.NewService(&mockSessionRepo{})
	sess := sessions.WorkoutSession{StartedAt: time.Now()}
	got, err := svc.Create(userID, sess)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got.UserID != userID {
		t.Fatalf("expected userID %s, got %s", userID, got.UserID)
	}
}

func TestCreate_RepoError(t *testing.T) {
	svc := sessions.NewService(&mockSessionRepo{err: errors.New("db error")})
	_, err := svc.Create(uuid.New(), sessions.WorkoutSession{})
	if err == nil {
		t.Fatal("expected error")
	}
}

func TestFinish_Success(t *testing.T) {
	svc := sessions.NewService(&mockSessionRepo{})
	if err := svc.Finish(uuid.New(), uuid.New()); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestFinish_RepoError(t *testing.T) {
	svc := sessions.NewService(&mockSessionRepo{err: errors.New("db error")})
	if err := svc.Finish(uuid.New(), uuid.New()); err == nil {
		t.Fatal("expected error")
	}
}

func TestDelete_Success(t *testing.T) {
	svc := sessions.NewService(&mockSessionRepo{})
	if err := svc.Delete(uuid.New(), uuid.New()); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestDelete_RepoError(t *testing.T) {
	svc := sessions.NewService(&mockSessionRepo{err: errors.New("db error")})
	if err := svc.Delete(uuid.New(), uuid.New()); err == nil {
		t.Fatal("expected error")
	}
}
