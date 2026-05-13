package api

import (
	"encoding/json"
	"net/http"
)

func Respond(w http.ResponseWriter, v any) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(v)
}
