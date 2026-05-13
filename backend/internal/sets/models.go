package sets

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type SetLog struct {
	ID          uuid.UUID      `gorm:"type:uuid;default:gen_random_uuid();primaryKey" json:"id"`
	SessionID   uuid.UUID      `gorm:"type:uuid;not null"                             json:"session_id"`
	ExerciseID  string         `gorm:"not null"                                       json:"exercise_id"`
	SetNumber   int            `gorm:"column:set_number;not null"                     json:"set_number"`
	Reps        int            `gorm:"not null"                                       json:"reps"`
	Weight      *float64       `                                                      json:"weight,omitempty"`
	CompletedAt time.Time      `gorm:"column:completed_at;not null"                   json:"completed_at"`
	CreatedAt   time.Time      `                                                      json:"created_at"`
	UpdatedAt   time.Time      `                                                      json:"updated_at"`
	DeletedAt   gorm.DeletedAt `gorm:"index"                                          json:"deleted_at,omitempty"`
}
