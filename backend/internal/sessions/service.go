package sessions

import (
	"time"

	"github.com/google/uuid"
)

type Service struct{ repo SessionRepository }

func NewService(repo SessionRepository) *Service { return &Service{repo: repo} }

func (s *Service) List(userID uuid.UUID) ([]WorkoutSession, error) {
	return s.repo.List(userID)
}

func (s *Service) Create(userID uuid.UUID, sess WorkoutSession) (WorkoutSession, error) {
	sess.UserID = userID
	return sess, s.repo.Create(&sess)
}

func (s *Service) Finish(id, userID uuid.UUID) error {
	return s.repo.Finish(id, userID, time.Now())
}

func (s *Service) Delete(id, userID uuid.UUID) error {
	return s.repo.Delete(id, userID)
}
