package exercises

import (
	"context"
	"time"
)

const cacheTTL = 24 * time.Hour

type Service struct {
	repo          ExerciseRepository
	provider      ExerciseProvider
	lastFetchedAt time.Time
}

func NewService(repo ExerciseRepository, provider ExerciseProvider) *Service {
	return &Service{repo: repo, provider: provider}
}

func (s *Service) List(_ context.Context, muscle string) ([]Exercise, error) {
	if s.isCacheStale() {
		_ = s.refreshCache()
	}
	return s.repo.List(muscle)
}

func (s *Service) isCacheStale() bool {
	return s.lastFetchedAt.IsZero() || time.Since(s.lastFetchedAt) > cacheTTL
}

func (s *Service) refreshCache() error {
	exercises, err := s.provider.FetchAll(context.Background())
	if err != nil {
		return err
	}
	if err := s.repo.Upsert(context.Background(), exercises); err != nil {
		return err
	}
	s.lastFetchedAt = time.Now()
	return nil
}
