package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/Nicolas1st/go-rs-rock-paper-scissors/model"
)

type result string

const (
	win  result = "win"
	loss result = "loss"
	draw result = "draw"
)

type GameResult struct {
	Result        string `json:"result"`
	YourMove      string `json:"yourMove"`
	OpponentsMove string `json:"opponentsMove"`
}

type GetGameStatusRequest struct {
	GameCode uint   `json:"gameCode"`
	UserName string `json:"userName"`
}

type GetGameStatusResponse struct {
	Status     string `json:"status"`
	GameResult GameResult
}

func (c *gameController) GetStatus(w http.ResponseWriter, r *http.Request) {
	// parse request
	var req GetGameStatusRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	var resp GetGameStatusResponse

	game, err := c.gameStorer.GetGame(req.GameCode)
	if err != nil {
		w.WriteHeader(http.StatusNotFound)
		return
	}
	resp.Status = string(game.Status)

	var gameResult GameResult

	// write game result depending on who has made the request
	playerIsPlayer1 := req.UserName == game.Player1.Name
	switch {
	case game.Player1.Move == game.Player2.Move:
		gameResult.Result = string(draw)
	case game.Player1.Move == model.Rock && game.Player2.Move == model.Scissors:
		if playerIsPlayer1 {
			gameResult.Result = string(win)
		} else {
			gameResult.Result = string(loss)
		}
	case game.Player1.Move == model.Scissors && game.Player2.Move == model.Paper:
		if playerIsPlayer1 {
			gameResult.Result = string(win)
		} else {
			gameResult.Result = string(loss)
		}
	case game.Player1.Move == model.Paper && game.Player2.Move == model.Rock:
		if playerIsPlayer1 {
			gameResult.Result = string(win)
		} else {
			gameResult.Result = string(loss)
		}
	default:
		if playerIsPlayer1 {
			// none of the victory checks above for player1 were called
			gameResult.Result = string(loss)
		} else {
			gameResult.Result = string(win)
		}
	}

	// see who players are
	switch req.UserName {
	case game.Player1.Name:
		gameResult.YourMove = string(game.Player1.Move)
		gameResult.OpponentsMove = string(game.Player2.Move)
	case game.Player2.Name:
		gameResult.YourMove = string(game.Player2.Move)
		gameResult.OpponentsMove = string(game.Player1.Move)
	default:
		w.WriteHeader(http.StatusBadRequest)
		return
	}

	resp.GameResult = gameResult

}
