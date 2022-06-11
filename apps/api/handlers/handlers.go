package handlers

import "github.com/Nicolas1st/go-rs-rock-paper-scissors/game"

type gameStorer interface {
	CreateGame(player1Name string) uint
	JoinGame(gameCode uint, player2Name string) error
	MakeMove(gameCode uint, playerName string, move game.Move) error
	GetGameStatus(gameCode uint, username string) (game.GameStatus, game.Result, error)
}

type gameController struct {
	gameStorer gameStorer
}

func NewGamesController(gameStorer gameStorer) *gameController {
	return &gameController{
		gameStorer: gameStorer,
	}
}
