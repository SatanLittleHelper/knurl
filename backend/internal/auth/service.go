package auth

import (
	"context"
	"errors"
	"strings"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"golang.org/x/crypto/bcrypt"
	"gorm.io/gorm"
)

var ErrInvalidCredentials = errors.New("invalid credentials")
var ErrEmailTaken = errors.New("email already taken")

type Service struct {
	db        *gorm.DB
	jwtSecret []byte
}

func NewService(db *gorm.DB, jwtSecret string) *Service {
	return &Service{db: db, jwtSecret: []byte(jwtSecret)}
}

func (s *Service) Register(_ context.Context, email, password string) (string, error) {
	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return "", err
	}

	user := User{Email: email, PasswordHash: string(hash)}
	result := s.db.Create(&user)
	if result.Error != nil {
		if isUniqueViolation(result.Error) {
			return "", ErrEmailTaken
		}
		return "", result.Error
	}

	return s.issueToken(user.ID)
}

func (s *Service) Login(_ context.Context, email, password string) (string, error) {
	var user User
	result := s.db.Where("email = ?", email).First(&user)
	if result.Error != nil {
		return "", ErrInvalidCredentials
	}

	if err := bcrypt.CompareHashAndPassword([]byte(user.PasswordHash), []byte(password)); err != nil {
		return "", ErrInvalidCredentials
	}

	return s.issueToken(user.ID)
}

func (s *Service) issueToken(userID uuid.UUID) (string, error) {
	claims := jwt.MapClaims{
		"sub": userID.String(),
		"exp": time.Now().Add(30 * 24 * time.Hour).Unix(),
	}
	return jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString(s.jwtSecret)
}

func isUniqueViolation(err error) bool {
	return err != nil && (strings.Contains(err.Error(), "unique") || strings.Contains(err.Error(), "23505"))
}
