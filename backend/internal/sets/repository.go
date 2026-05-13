package sets

import (
	"github.com/google/uuid"
	"gorm.io/gorm"
)

type SetRepository interface {
	List(sessionID uuid.UUID) ([]SetLog, error)
	Create(log *SetLog) error
	FindByID(id uuid.UUID) (SetLog, error)
	Update(existing SetLog, patch SetLog) (SetLog, error)
	Delete(id uuid.UUID) error
}

type gormSetRepo struct {
	db *gorm.DB
}

func NewGormSetRepo(db *gorm.DB) SetRepository {
	return &gormSetRepo{db: db}
}

func (r *gormSetRepo) List(sessionID uuid.UUID) ([]SetLog, error) {
	var logs []SetLog
	return logs, r.db.Where("session_id = ?", sessionID).Order("completed_at").Find(&logs).Error
}

func (r *gormSetRepo) Create(log *SetLog) error {
	return r.db.Create(log).Error
}

func (r *gormSetRepo) FindByID(id uuid.UUID) (SetLog, error) {
	var log SetLog
	return log, r.db.First(&log, "id = ?", id).Error
}

func (r *gormSetRepo) Update(existing SetLog, patch SetLog) (SetLog, error) {
	result := r.db.Model(&existing).Updates(patch)
	return existing, result.Error
}

func (r *gormSetRepo) Delete(id uuid.UUID) error {
	return r.db.Where("id = ?", id).Delete(&SetLog{}).Error
}
