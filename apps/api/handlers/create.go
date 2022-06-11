package handlers

import (
	"encoding/json"
	"net/http"
)

type CreateGameRequest struct {
	UserName string `json:"userName"`
}

type CreateGameResponse struct {
	GameCode uint `json:"gameCode"`
}

func (c *gameController) CreateGame(w http.ResponseWriter, r *http.Request) {
	// parse request
	var req CreateGameRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	if req.UserName == "" {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	// create game
	var resp CreateGameResponse

	gameCode := c.gameStorer.CreateGame(req.UserName)
	resp.GameCode = gameCode
	json.NewEncoder(w).Encode(resp)
}
