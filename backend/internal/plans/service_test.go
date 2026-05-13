package plans_test

import (
	"errors"
	"testing"

	"github.com/google/uuid"
	"github.com/satanlittlehelper/knurl/backend/internal/plans"
)

type mockPlanRepo struct {
	listPlansResult  []plans.WorkoutPlan
	createPlanResult plans.WorkoutPlan
	listDaysResult   []plans.WorkoutDay
	createDayResult  plans.WorkoutDay
	addExResult      plans.PlannedExercise
	err              error
}

func (m *mockPlanRepo) ListPlans(_ uuid.UUID) ([]plans.WorkoutPlan, error) {
	return m.listPlansResult, m.err
}
func (m *mockPlanRepo) CreatePlan(plan plans.WorkoutPlan) (plans.WorkoutPlan, error) {
	return m.createPlanResult, m.err
}
func (m *mockPlanRepo) DeletePlan(_, _ uuid.UUID) error { return m.err }
func (m *mockPlanRepo) ListDays(_ uuid.UUID) ([]plans.WorkoutDay, error) {
	return m.listDaysResult, m.err
}
func (m *mockPlanRepo) CreateDay(day plans.WorkoutDay) (plans.WorkoutDay, error) {
	return m.createDayResult, m.err
}
func (m *mockPlanRepo) AddExercise(ex plans.PlannedExercise) (plans.PlannedExercise, error) {
	return m.addExResult, m.err
}

func TestListPlans_Success(t *testing.T) {
	userID := uuid.New()
	want := []plans.WorkoutPlan{{UserID: userID, Name: "Plan A"}}
	svc := plans.NewService(&mockPlanRepo{listPlansResult: want})
	got, err := svc.ListPlans(userID)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(got) != 1 || got[0].Name != "Plan A" {
		t.Fatalf("unexpected result: %v", got)
	}
}

func TestListPlans_RepoError(t *testing.T) {
	svc := plans.NewService(&mockPlanRepo{err: errors.New("db error")})
	_, err := svc.ListPlans(uuid.New())
	if err == nil {
		t.Fatal("expected error")
	}
}

func TestCreatePlan_Success(t *testing.T) {
	userID := uuid.New()
	want := plans.WorkoutPlan{UserID: userID, Name: "My Plan"}
	svc := plans.NewService(&mockPlanRepo{createPlanResult: want})
	got, err := svc.CreatePlan(userID, "My Plan")
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got.Name != "My Plan" {
		t.Fatalf("unexpected plan name: %s", got.Name)
	}
}

func TestDeletePlan_Success(t *testing.T) {
	svc := plans.NewService(&mockPlanRepo{})
	if err := svc.DeletePlan(uuid.New(), uuid.New()); err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
}

func TestListDays_Success(t *testing.T) {
	planID := uuid.New()
	want := []plans.WorkoutDay{{PlanID: planID, DayOfWeek: 1}}
	svc := plans.NewService(&mockPlanRepo{listDaysResult: want})
	got, err := svc.ListDays(planID)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if len(got) != 1 {
		t.Fatalf("expected 1 day, got %d", len(got))
	}
}

func TestCreateDay_Success(t *testing.T) {
	planID := uuid.New()
	want := plans.WorkoutDay{PlanID: planID, DayOfWeek: 3}
	svc := plans.NewService(&mockPlanRepo{createDayResult: want})
	got, err := svc.CreateDay(planID, 3)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got.DayOfWeek != 3 {
		t.Fatalf("expected day 3, got %d", got.DayOfWeek)
	}
}

func TestAddExercise_Success(t *testing.T) {
	ex := plans.PlannedExercise{ExerciseID: "squat", Sets: 3, Reps: 10}
	svc := plans.NewService(&mockPlanRepo{addExResult: ex})
	got, err := svc.AddExercise(ex)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}
	if got.ExerciseID != "squat" {
		t.Fatalf("unexpected exercise: %s", got.ExerciseID)
	}
}
