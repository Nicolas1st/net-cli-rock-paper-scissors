package game

import (
	"testing"
)

func TestMakeMove(t *testing.T) {
	gs := NewGameStorer()
	player1Name := "player1"
	player2Name := "player2"

	gameCode := gs.CreateGame(player1Name)
	gs.JoinGame(gameCode, player2Name)

	game, ok := gs.games[gameCode]
	if !ok {
		t.Error("The game should not exist")
	}

	// the third player can not make a move
	if err := gs.MakeMove(gameCode, "player3", Rock); err == nil {
		t.Error("The third player should not be able to make a move")
	}

	if err := gs.MakeMove(gameCode, player1Name, Rock); err != nil {
		t.Error("Should be possible to make move for the first time")
	}

	if game.Status != InProcess {
		t.Error("The game should have the status ", InProcess)
	}

	if err := gs.MakeMove(gameCode, player1Name, Rock); err == nil {
		t.Error("Should not be possible to make move for the second time")
	}

	if game.Status != InProcess {
		t.Error("The game should have the status", InProcess)
	}

	if err := gs.MakeMove(gameCode, player2Name, Rock); err != nil {
		t.Error("Should be possible to make move for the first time")
	}

	if game.Status != Finished {
		t.Log(game.Status)
		t.Error("The game should have the status", Finished)
	}
}
