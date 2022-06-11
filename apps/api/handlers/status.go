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

type GetGameNotFinishedStatusResponse struct {
	Status game.GameStatus `json:"status"`
}

type GetGameFinishedStatusResponse struct {
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

	status, res, err := c.gameStorer.GetGameStatus(req.GameCode, req.UserName)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		return
	}

	if status == game.Finished {
		var resp GetGameFinishedStatusResponse
		resp.Status = status
		resp.GameResult = res

		json.NewEncoder(w).Encode(&resp)
	} else {
		var resp GetGameNotFinishedStatusResponse
		resp.Status = status

		json.NewEncoder(w).Encode(&resp)
	}
}
