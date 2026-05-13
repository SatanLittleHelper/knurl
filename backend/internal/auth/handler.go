package auth

import (
	"encoding/json"
	"errors"
	"io"
	"log"
	"net/http"
	"strings"

	"github.com/satanlittlehelper/knurl/backend/internal/api"
)

type Handler struct {
	svc *Service
}

func NewHandler(svc *Service) *Handler {
	return &Handler{svc: svc}
}

type authRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

func (h *Handler) Register(w http.ResponseWriter, r *http.Request) {
	var req authRequest
	if err := json.NewDecoder(io.LimitReader(r.Body, 1024)).Decode(&req); err != nil {
		api.Error(w, http.StatusBadRequest, "bad request")
		return
	}
	req.Email = strings.TrimSpace(req.Email)
	if req.Email == "" || req.Password == "" {
		api.Error(w, http.StatusBadRequest, "email and password required")
		return
	}

	token, err := h.svc.Register(r.Context(), req.Email, req.Password)
	if errors.Is(err, ErrEmailTaken) {
		api.Error(w, http.StatusConflict, "email already taken")
		return
	}
	if err != nil {
		log.Printf("register: %v", err)
		api.Error(w, http.StatusInternalServerError, "internal error")
		return
	}

	api.Respond(w, http.StatusCreated, map[string]string{"token": token})
}

func (h *Handler) Login(w http.ResponseWriter, r *http.Request) {
	var req authRequest
	if err := json.NewDecoder(io.LimitReader(r.Body, 1024)).Decode(&req); err != nil {
		api.Error(w, http.StatusBadRequest, "bad request")
		return
	}
	req.Email = strings.TrimSpace(req.Email)

	token, err := h.svc.Login(r.Context(), req.Email, req.Password)
	if errors.Is(err, ErrInvalidCredentials) {
		api.Error(w, http.StatusUnauthorized, "invalid credentials")
		return
	}
	if err != nil {
		log.Printf("login: %v", err)
		api.Error(w, http.StatusInternalServerError, "internal error")
		return
	}

	api.Respond(w, http.StatusOK, map[string]string{"token": token})
}
