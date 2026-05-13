package exercises

import (
	"context"
	"time"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

const cacheTTL = 24 * time.Hour

type Service struct {
	db            *gorm.DB
	provider      ExerciseProvider
	lastFetchedAt time.Time
}

func NewService(db *gorm.DB, provider ExerciseProvider) *Service {
	return &Service{db: db, provider: provider}
}

func (s *Service) List(_ context.Context, muscle string) ([]Exercise, error) {
	if s.isCacheStale() {
		_ = s.refreshCache()
	}
	return s.fromDB(muscle)
}

func (s *Service) isCacheStale() bool {
	return s.lastFetchedAt.IsZero() || time.Since(s.lastFetchedAt) > cacheTTL
}

func (s *Service) refreshCache() error {
	exercises, err := s.provider.FetchAll(context.Background())
	if err != nil {
		return err
	}
	if err := s.db.Clauses(clause.OnConflict{UpdateAll: true}).Create(&exercises).Error; err != nil {
		return err
	}
	s.lastFetchedAt = time.Now()
	return nil
}

func (s *Service) fromDB(muscle string) ([]Exercise, error) {
	var exercises []Exercise
	query := s.db.Order("name")
	if muscle != "" {
		query = query.Where("muscle_group = ?", muscle)
	}
	result := query.Find(&exercises)
	return exercises, result.Error
}
