package sessions

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Service struct{ db *gorm.DB }

func NewService(db *gorm.DB) *Service { return &Service{db: db} }

func (s *Service) List(userID uuid.UUID) ([]WorkoutSession, error) {
	var sessions []WorkoutSession
	result := s.db.Where("user_id = ?", userID).Order("started_at DESC").Find(&sessions)
	return sessions, result.Error
}

func (s *Service) Create(userID uuid.UUID, sess WorkoutSession) (WorkoutSession, error) {
	sess.UserID = userID
	result := s.db.Create(&sess)
	return sess, result.Error
}

func (s *Service) Finish(id, userID uuid.UUID) error {
	now := time.Now()
	result := s.db.Model(&WorkoutSession{}).
		Where("id = ? AND user_id = ?", id, userID).
		Update("finished_at", now)
	return result.Error
}

func (s *Service) Delete(id, userID uuid.UUID) error {
	result := s.db.Where("id = ? AND user_id = ?", id, userID).Delete(&WorkoutSession{})
	return result.Error
}
