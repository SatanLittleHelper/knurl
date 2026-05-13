package sets

import "github.com/google/uuid"

type Service struct{ repo SetRepository }

func NewService(repo SetRepository) *Service { return &Service{repo: repo} }

func (s *Service) List(sessionID uuid.UUID) ([]SetLog, error) {
	return s.repo.List(sessionID)
}

func (s *Service) Create(sessionID uuid.UUID, log SetLog) (SetLog, error) {
	log.SessionID = sessionID
	return log, s.repo.Create(&log)
}

func (s *Service) Update(id uuid.UUID, patch SetLog) (SetLog, error) {
	existing, err := s.repo.FindByID(id)
	if err != nil {
		return SetLog{}, err
	}
	patch.ID = id
	return s.repo.Update(existing, patch)
}

func (s *Service) Delete(id uuid.UUID) error {
	return s.repo.Delete(id)
}
