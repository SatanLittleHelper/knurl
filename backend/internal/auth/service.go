package auth

import (
	"context"
	"errors"
	"log"
	"net/mail"
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/jackc/pgx/v5/pgconn"
	"golang.org/x/crypto/bcrypt"
)

var ErrInvalidCredentials = errors.New("invalid credentials")
var ErrEmailTaken = errors.New("email already taken")

type Service struct {
	repo      UserRepository
	jwtSecret []byte
}

func NewService(repo UserRepository, jwtSecret string) *Service {
	if len(jwtSecret) < 32 {
		log.Println("warning: JWT_SECRET is shorter than 32 bytes")
	}
	return &Service{repo: repo, jwtSecret: []byte(jwtSecret)}
}

func (s *Service) Register(ctx context.Context, email, password string) (string, error) {
	if len(password) < 6 {
		return "", errors.New("password must be at least 6 characters")
	}
	if _, err := mail.ParseAddress(email); err != nil {
		return "", errors.New("invalid email")
	}

	hash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return "", err
	}

	user := User{Email: email, PasswordHash: string(hash)}
	if err := s.repo.Create(ctx, &user); err != nil {
		if isUniqueViolation(err) {
			return "", ErrEmailTaken
		}
		return "", err
	}

	return s.issueToken(user.ID)
}

func (s *Service) Login(ctx context.Context, email, password string) (string, error) {
	user, err := s.repo.FindByEmail(ctx, email)
	if err != nil {
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
	var pgErr *pgconn.PgError
	return errors.As(err, &pgErr) && pgErr.Code == "23505"
}
