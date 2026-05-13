package sessions

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type SessionRepository interface {
	List(userID uuid.UUID) ([]WorkoutSession, error)
	Create(sess *WorkoutSession) error
	Finish(id, userID uuid.UUID, at time.Time) error
	Delete(id, userID uuid.UUID) error
}

type gormSessionRepo struct {
	db *gorm.DB
}

func NewGormSessionRepo(db *gorm.DB) SessionRepository {
	return &gormSessionRepo{db: db}
}

func (r *gormSessionRepo) List(userID uuid.UUID) ([]WorkoutSession, error) {
	var sessions []WorkoutSession
	return sessions, r.db.Where("user_id = ?", userID).Order("started_at DESC").Find(&sessions).Error
}

func (r *gormSessionRepo) Create(sess *WorkoutSession) error {
	return r.db.Create(sess).Error
}

func (r *gormSessionRepo) Finish(id, userID uuid.UUID, at time.Time) error {
	return r.db.Model(&WorkoutSession{}).
		Where("id = ? AND user_id = ?", id, userID).
		Update("finished_at", at).Error
}

func (r *gormSessionRepo) Delete(id, userID uuid.UUID) error {
	return r.db.Where("id = ? AND user_id = ?", id, userID).Delete(&WorkoutSession{}).Error
}
