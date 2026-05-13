package exercises_test

import (
	"context"
	"testing"

	"github.com/satanlittlehelper/knurl/backend/internal/exercises"
)

type mockExerciseRepo struct {
	listResult []exercises.Exercise
	listErr    error
}

func (m *mockExerciseRepo) Upsert(_ context.Context, _ []exercises.Exercise) error { return nil }

func (m *mockExerciseRepo) List(_ string) ([]exercises.Exercise, error) {
	return m.listResult, m.listErr
}

func TestList_ReturnsRepoData(t *testing.T) {
	want := []exercises.Exercise{{ID: "squat", Name: "Squat", MuscleGroup: "legs"}}
	svc := exercises.NewService(&mockExerciseRepo{listResult: want}, exercises.StubProvider{})
	got, err := svc.List(context.Background(), "")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(got) == 0 {
		t.Fatal("expected non-empty result from repo")
	}
}
