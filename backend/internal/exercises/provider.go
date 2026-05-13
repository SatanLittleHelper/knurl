package exercises

import "context"

type ExerciseProvider interface {
	FetchAll(ctx context.Context) ([]Exercise, error)
}

type StubProvider struct{}

func (StubProvider) FetchAll(_ context.Context) ([]Exercise, error) {
	return []Exercise{
		{ID: "bench-press", Name: "Жим лёжа", MuscleGroup: "chest", Equipment: "barbell"},
		{ID: "squat", Name: "Присед", MuscleGroup: "legs", Equipment: "barbell"},
		{ID: "deadlift", Name: "Становая тяга", MuscleGroup: "back", Equipment: "barbell"},
		{ID: "pull-up", Name: "Подтягивания", MuscleGroup: "back", Equipment: "bodyweight"},
		{ID: "overhead-press", Name: "Жим стоя", MuscleGroup: "shoulders", Equipment: "barbell"},
	}, nil
}
