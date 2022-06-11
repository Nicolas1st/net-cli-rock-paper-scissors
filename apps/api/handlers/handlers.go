package handlers

import "github.com/Nicolas1st/go-rs-rock-paper-scissors/model"

type gameStorer interface {
	CreateGame(player1Name string) uint
	JoinGame(gameCode uint, player2Name string) error
	MakeMove(gameCode uint, playerName string, move model.Move) error
	GetGame(gameCode uint) (*model.Game, error)
}

type gameController struct {
	gameStorer gameStorer
}

func NewGamesController(gameStorer) *gameController {
	return &gameController{}
}
