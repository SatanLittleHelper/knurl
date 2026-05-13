package exercises

import (
	"context"

	"gorm.io/gorm"
	"gorm.io/gorm/clause"
)

type ExerciseRepository interface {
	Upsert(ctx context.Context, exercises []Exercise) error
	List(muscle string) ([]Exercise, error)
}

type gormExerciseRepo struct {
	db *gorm.DB
}

func NewGormExerciseRepo(db *gorm.DB) ExerciseRepository {
	return &gormExerciseRepo{db: db}
}

func (r *gormExerciseRepo) Upsert(ctx context.Context, exercises []Exercise) error {
	return r.db.WithContext(ctx).Clauses(clause.OnConflict{UpdateAll: true}).Create(&exercises).Error
}

func (r *gormExerciseRepo) List(muscle string) ([]Exercise, error) {
	var exercises []Exercise
	query := r.db.Order("name")
	if muscle != "" {
		query = query.Where("muscle_group = ?", muscle)
	}
	return exercises, query.Find(&exercises).Error
}
