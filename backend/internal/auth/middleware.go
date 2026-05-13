package auth

import (
	"context"
	"net/http"
	"strings"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/satanlittlehelper/knurl/backend/internal/api"
)

type contextKey string

const userIDKey contextKey = "userID"

func Middleware(jwtSecret string) func(http.Handler) http.Handler {
	secret := []byte(jwtSecret)

	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			header := r.Header.Get("Authorization")

			if !strings.HasPrefix(header, "Bearer ") {
				api.Error(w, http.StatusUnauthorized, "unauthorized")
				return
			}

			tokenStr := strings.TrimPrefix(header, "Bearer ")

			token, err := jwt.Parse(tokenStr, func(t *jwt.Token) (any, error) {
				if _, ok := t.Method.(*jwt.SigningMethodHMAC); !ok {
					return nil, jwt.ErrSignatureInvalid
				}
				return secret, nil
			})
			if err != nil || !token.Valid {
				api.Error(w, http.StatusUnauthorized, "unauthorized")
				return
			}

			sub, err := token.Claims.GetSubject()
			if err != nil {
				api.Error(w, http.StatusUnauthorized, "unauthorized")
				return
			}

			userID, err := uuid.Parse(sub)
			if err != nil {
				api.Error(w, http.StatusUnauthorized, "unauthorized")
				return
			}

			ctx := context.WithValue(r.Context(), userIDKey, userID)
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

func UserIDFromCtx(ctx context.Context) (uuid.UUID, bool) {
	id, ok := ctx.Value(userIDKey).(uuid.UUID)
	return id, ok
}
