package plans

import "github.com/google/uuid"

type Service struct {
	repo PlanRepository
}

func NewService(repo PlanRepository) *Service { return &Service{repo: repo} }

func (s *Service) ListPlans(userID uuid.UUID) ([]WorkoutPlan, error) {
	return s.repo.ListPlans(userID)
}

func (s *Service) CreatePlan(userID uuid.UUID, name string) (WorkoutPlan, error) {
	return s.repo.CreatePlan(WorkoutPlan{UserID: userID, Name: name})
}

func (s *Service) DeletePlan(id, userID uuid.UUID) error {
	return s.repo.DeletePlan(id, userID)
}

func (s *Service) ListDays(planID uuid.UUID) ([]WorkoutDay, error) {
	return s.repo.ListDays(planID)
}

func (s *Service) CreateDay(planID uuid.UUID, dayOfWeek int) (WorkoutDay, error) {
	return s.repo.CreateDay(WorkoutDay{PlanID: planID, DayOfWeek: dayOfWeek})
}

func (s *Service) AddExercise(ex PlannedExercise) (PlannedExercise, error) {
	return s.repo.AddExercise(ex)
}
