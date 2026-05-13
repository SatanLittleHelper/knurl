package plans

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type WorkoutPlan struct {
	ID        uuid.UUID      `gorm:"type:uuid;default:gen_random_uuid();primaryKey" json:"id"`
	UserID    uuid.UUID      `gorm:"type:uuid;not null"                             json:"user_id"`
	Name      string         `gorm:"not null"                                       json:"name"`
	CreatedAt time.Time      `                                                      json:"created_at"`
	UpdatedAt time.Time      `                                                      json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index"                                          json:"deleted_at,omitempty"`
}

type WorkoutDay struct {
	ID        uuid.UUID      `gorm:"type:uuid;default:gen_random_uuid();primaryKey" json:"id"`
	PlanID    uuid.UUID      `gorm:"type:uuid;not null"                             json:"plan_id"`
	DayOfWeek int            `gorm:"not null"                                       json:"day_of_week"`
	UpdatedAt time.Time      `                                                      json:"updated_at"`
	DeletedAt gorm.DeletedAt `gorm:"index"                                          json:"deleted_at,omitempty"`
}

type PlannedExercise struct {
	ID           uuid.UUID      `gorm:"type:uuid;default:gen_random_uuid();primaryKey" json:"id"`
	DayID        uuid.UUID      `gorm:"type:uuid;not null"                             json:"day_id"`
	ExerciseID   string         `gorm:"not null"                                       json:"exercise_id"`
	Sets         int            `gorm:"not null"                                       json:"sets"`
	Reps         int            `gorm:"not null"                                       json:"reps"`
	TargetWeight *float64       `gorm:"column:target_weight"                           json:"target_weight,omitempty"`
	Position     int            `gorm:"not null"                                       json:"position"`
	UpdatedAt    time.Time      `                                                      json:"updated_at"`
	DeletedAt    gorm.DeletedAt `gorm:"index"                                          json:"deleted_at,omitempty"`
}
