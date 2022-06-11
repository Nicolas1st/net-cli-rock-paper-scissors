package handlers

import (
	"net/http"
)

type JoinGameRequest struct {
	GameCode uint   `json:"gameCode"`
	UserName string `json:"userName"`
}

func (c *gameController) JoinGame(w http.ResponseWriter, r *http.Request) {
	// parse request
	var req JoinGameRequest
	if err := c.gameStorer.JoinGame(req.GameCode, req.UserName); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		return
	}
}
