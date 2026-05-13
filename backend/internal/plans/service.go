package plans

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Service struct {
	db *gorm.DB
}

func NewService(db *gorm.DB) *Service { return &Service{db: db} }

func (s *Service) ListPlans(userID uuid.UUID) ([]WorkoutPlan, error) {
	var plans []WorkoutPlan
	result := s.db.Where("user_id = ?", userID).Order("created_at DESC").Find(&plans)
	return plans, result.Error
}

func (s *Service) CreatePlan(userID uuid.UUID, name string) (WorkoutPlan, error) {
	plan := WorkoutPlan{UserID: userID, Name: name}
	result := s.db.Create(&plan)
	return plan, result.Error
}

func (s *Service) DeletePlan(id, userID uuid.UUID) error {
	result := s.db.Where("id = ? AND user_id = ?", id, userID).Delete(&WorkoutPlan{})
	return result.Error
}

func (s *Service) ListDays(planID uuid.UUID) ([]WorkoutDay, error) {
	var days []WorkoutDay
	result := s.db.Where("plan_id = ?", planID).Order("day_of_week").Find(&days)
	return days, result.Error
}

func (s *Service) CreateDay(planID uuid.UUID, dayOfWeek int) (WorkoutDay, error) {
	day := WorkoutDay{PlanID: planID, DayOfWeek: dayOfWeek}
	result := s.db.Create(&day)
	return day, result.Error
}

func (s *Service) AddExercise(ex PlannedExercise) (PlannedExercise, error) {
	result := s.db.Create(&ex)
	return ex, result.Error
}
