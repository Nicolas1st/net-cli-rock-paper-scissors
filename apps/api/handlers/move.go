package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/Nicolas1st/go-rs-rock-paper-scissors/model"
)

type MakeMoveRequest struct {
	GameCode uint       `json:"gameCode"`
	UserName string     `json:"userName"`
	Move     model.Move `json:"move"`
}

func (c *gameController) MakeMove(w http.ResponseWriter, r *http.Request) {
	// parse request
	var req MakeMoveRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	if err := c.gameStorer.MakeMove(req.GameCode, req.UserName, req.Move); err != nil {
		w.WriteHeader(http.StatusInternalServerError)
		return
	}
}
