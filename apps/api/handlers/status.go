package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/Nicolas1st/go-rs-rock-paper-scissors/game"
)

type GetGameStatusRequest struct {
	GameCode uint   `json:"gameCode"`
	UserName string `json:"userName"`
}

type GetGameStatusResponse struct {
	Status     game.GameStatus `json:"status"`
	GameResult game.Result     `json:"gameResult"`
}

func (c *gameController) GetStatus(w http.ResponseWriter, r *http.Request) {
	// parse request
	var req GetGameStatusRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	var resp GetGameStatusResponse

	status, res, err := c.gameStorer.GetGameStatus(req.GameCode, req.UserName)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		return
	}

	resp.Status = status
	resp.GameResult = res

	json.NewEncoder(w).Encode(&resp)
}
