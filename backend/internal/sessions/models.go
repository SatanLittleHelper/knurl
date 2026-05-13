package sessions

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type WorkoutSession struct {
	ID         uuid.UUID      `gorm:"type:uuid;default:gen_random_uuid();primaryKey" json:"id"`
	UserID     uuid.UUID      `gorm:"type:uuid;not null"                             json:"user_id"`
	PlanID     *uuid.UUID     `gorm:"type:uuid"                                      json:"plan_id,omitempty"`
	DayID      *uuid.UUID     `gorm:"type:uuid"                                      json:"day_id,omitempty"`
	StartedAt  time.Time      `gorm:"not null"                                       json:"started_at"`
	FinishedAt *time.Time     `                                                      json:"finished_at,omitempty"`
	CreatedAt  time.Time      `                                                      json:"created_at"`
	UpdatedAt  time.Time      `                                                      json:"updated_at"`
	DeletedAt  gorm.DeletedAt `gorm:"index"                                          json:"deleted_at,omitempty"`
}
