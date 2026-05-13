package sets_test

import (
	"errors"
	"testing"
	"time"

	"github.com/google/uuid"
	"github.com/satanlittlehelper/knurl/backend/internal/sets"
)

type mockSetRepo struct {
	listResult   []sets.SetLog
	findResult   sets.SetLog
	updateResult sets.SetLog
	err          error
	findErr      error
}

func (m *mockSetRepo) List(_ uuid.UUID) ([]sets.SetLog, error) {
	return m.listResult, m.err
}
func (m *mockSetRepo) Create(log *sets.SetLog) error { return m.err }
func (m *mockSetRepo) FindByID(_ uuid.UUID) (sets.SetLog, error) {
	return m.findResult, m.findErr
}
func (m *mockSetRepo) Update(_ sets.SetLog, _ sets.SetLog) (sets.SetLog, error) {
	return m.updateResult, m.err
}
func (m *mockSetRepo) Delete(_ uuid.UUID) error { return m.err }

func TestList_Success(t *testing.T) {
	sessionID := uuid.New()
	want := []sets.SetLog{{SessionID: sessionID, ExerciseID: "squat", SetNumber: 1, Reps: 10, CompletedAt: time.Now()}}
	svc := sets.NewService(&mockSetRepo{listResult: want})
	got, err := svc.List(sessionID)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(got) != 1 {
		t.Fatalf("expected 1 set, got %d", len(got))
	}
}

func TestList_RepoError(t *testing.T) {
	svc := sets.NewService(&mockSetRepo{err: errors.New("db error")})
	_, err := svc.List(uuid.New())
	if err == nil {
		t.Fatal("expected error")
	}
}

func TestCreate_Success_SessionIDAssigned(t *testing.T) {
	sessionID := uuid.New()
	svc := sets.NewService(&mockSetRepo{})
	log := sets.SetLog{ExerciseID: "squat", SetNumber: 1, Reps: 10, CompletedAt: time.Now()}
	got, err := svc.Create(sessionID, log)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got.SessionID != sessionID {
		t.Fatalf("expected sessionID %s, got %s", sessionID, got.SessionID)
	}
}

func TestCreate_RepoError(t *testing.T) {
	svc := sets.NewService(&mockSetRepo{err: errors.New("db error")})
	_, err := svc.Create(uuid.New(), sets.SetLog{})
	if err == nil {
		t.Fatal("expected error")
	}
}

func TestUpdate_Success(t *testing.T) {
	id := uuid.New()
	existing := sets.SetLog{ID: id, ExerciseID: "squat", SetNumber: 1, Reps: 8, CompletedAt: time.Now()}
	updated := sets.SetLog{ID: id, ExerciseID: "squat", SetNumber: 1, Reps: 10, CompletedAt: time.Now()}
	svc := sets.NewService(&mockSetRepo{findResult: existing, updateResult: updated})
	got, err := svc.Update(id, sets.SetLog{Reps: 10})
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got.Reps != 10 {
		t.Fatalf("expected 10 reps, got %d", got.Reps)
	}
}

func TestUpdate_FindByIDError(t *testing.T) {
	svc := sets.NewService(&mockSetRepo{findErr: errors.New("not found")})
	_, err := svc.Update(uuid.New(), sets.SetLog{})
	if err == nil {
		t.Fatal("expected error")
	}
}

func TestUpdate_UpdateError(t *testing.T) {
	existing := sets.SetLog{ID: uuid.New(), CompletedAt: time.Now()}
	svc := sets.NewService(&mockSetRepo{findResult: existing, err: errors.New("db error")})
	_, err := svc.Update(existing.ID, sets.SetLog{Reps: 5})
	if err == nil {
		t.Fatal("expected error")
	}
}

func TestDelete_Success(t *testing.T) {
	svc := sets.NewService(&mockSetRepo{})
	if err := svc.Delete(uuid.New()); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestDelete_RepoError(t *testing.T) {
	svc := sets.NewService(&mockSetRepo{err: errors.New("db error")})
	if err := svc.Delete(uuid.New()); err == nil {
		t.Fatal("expected error")
	}
}
