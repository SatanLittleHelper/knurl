package plans

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type PlanRepository interface {
	ListPlans(userID uuid.UUID) ([]WorkoutPlan, error)
	CreatePlan(plan WorkoutPlan) (WorkoutPlan, error)
	DeletePlan(id, userID uuid.UUID) error
	ListDays(planID uuid.UUID) ([]WorkoutDay, error)
	CreateDay(day WorkoutDay) (WorkoutDay, error)
	AddExercise(ex PlannedExercise) (PlannedExercise, error)
}

type gormPlanRepo struct {
	db *gorm.DB
}

func NewGormPlanRepo(db *gorm.DB) PlanRepository {
	return &gormPlanRepo{db: db}
}

func (r *gormPlanRepo) ListPlans(userID uuid.UUID) ([]WorkoutPlan, error) {
	var plans []WorkoutPlan
	return plans, r.db.Where("user_id = ?", userID).Order("created_at DESC").Find(&plans).Error
}

func (r *gormPlanRepo) CreatePlan(plan WorkoutPlan) (WorkoutPlan, error) {
	return plan, r.db.Create(&plan).Error
}

func (r *gormPlanRepo) DeletePlan(id, userID uuid.UUID) error {
	return r.db.Where("id = ? AND user_id = ?", id, userID).Delete(&WorkoutPlan{}).Error
}

func (r *gormPlanRepo) ListDays(planID uuid.UUID) ([]WorkoutDay, error) {
	var days []WorkoutDay
	return days, r.db.Where("plan_id = ?", planID).Order("day_of_week").Find(&days).Error
}

func (r *gormPlanRepo) CreateDay(day WorkoutDay) (WorkoutDay, error) {
	return day, r.db.Create(&day).Error
}

func (r *gormPlanRepo) AddExercise(ex PlannedExercise) (PlannedExercise, error) {
	return ex, r.db.Create(&ex).Error
}
