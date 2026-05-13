package api

import (
	"encoding/json"
	"log"
	"net/http"
)

func Respond(w http.ResponseWriter, status int, v any) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if err := json.NewEncoder(w).Encode(v); err != nil {
		log.Printf("api.Respond: encode: %v", err)
	}
}

func Error(w http.ResponseWriter, status int, message string) {
	Respond(w, status, map[string]string{"error": message})
}

func NoContent(w http.ResponseWriter) {
	w.WriteHeader(http.StatusNoContent)
}
