package sets

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type Service struct{ db *gorm.DB }

func NewService(db *gorm.DB) *Service { return &Service{db: db} }

func (s *Service) List(sessionID uuid.UUID) ([]SetLog, error) {
	var logs []SetLog
	result := s.db.Where("session_id = ?", sessionID).Order("completed_at").Find(&logs)
	return logs, result.Error
}

func (s *Service) Create(sessionID uuid.UUID, log SetLog) (SetLog, error) {
	log.SessionID = sessionID
	result := s.db.Create(&log)
	return log, result.Error
}

func (s *Service) Update(id uuid.UUID, patch SetLog) (SetLog, error) {
	var log SetLog
	if err := s.db.First(&log, "id = ?", id).Error; err != nil {
		return SetLog{}, err
	}
	patch.ID = id
	result := s.db.Model(&log).Updates(patch)
	return log, result.Error
}

func (s *Service) Delete(id uuid.UUID) error {
	result := s.db.Where("id = ?", id).Delete(&SetLog{})
	return result.Error
}
