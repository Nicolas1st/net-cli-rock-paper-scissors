package game

import (
	"testing"
)

func TestMakeMove(t *testing.T) {
	gs := NewGameStorer()
	player1Name := "player1"
	player2Name := "player2"

	gameCode, game, wasCreated := setupGame(gs, player1Name, player2Name)
	if !wasCreated {
		t.Errorf("Failed to create the game")
	}
	gs.JoinGame(gameCode, player2Name)

	if game.Status != InProcess {
		t.Error("The game should have the status ", InProcess)
	}

	// try making impossible move
	before := game.LastModified
	if err := gs.MakeMove(gameCode, player1Name, Move("impossible move")); err == nil {
		t.Error("Should now allow making impossible moves")
	}

	// should not be updated
	if game.LastModified.After(before) {
		t.Errorf("Last modified should not be updated")
	}

	// the third player can not make a move
	before = game.LastModified
	if err := gs.MakeMove(gameCode, "player3", Rock); err == nil {
		t.Error("The third player should not be able to make a move")
	}

	// should not be updated
	if game.LastModified.After(before) {
		t.Errorf("Last modified should not be updated")
	}

	// test first player make move for the first time
	before = game.LastModified
	if err := gs.MakeMove(gameCode, player1Name, Rock); err != nil {
		t.Error("Should be possible to make move for the first time")
	}

	// should be updated
	if !game.LastModified.After(before) {
		t.Errorf("Last modified should not be updated")
	}

	// test first player make move for the second time
	before = game.LastModified
	if err := gs.MakeMove(gameCode, player1Name, Rock); err == nil {
		t.Error("Should not be possible to make move for the second time")
	}

	if game.Status != InProcess {
		t.Error("The game should have the status", InProcess)
	}

	// should not be updated
	if game.LastModified.After(before) {
		t.Errorf("Last modified should not be updated")
	}

	// test second player make move for the first time
	before = game.LastModified
	if err := gs.MakeMove(gameCode, player2Name, Rock); err != nil {
		t.Error("Should be possible to make move for the first time")
	}

	// should be updated
	if !game.LastModified.After(before) {
		t.Errorf("Last modified should not be updated")
	}

	// test second player make move for the second time
	before = game.LastModified
	if err := gs.MakeMove(gameCode, player2Name, Rock); err == nil {
		t.Error("Should not be possible to make move for the second time")
	}

	// should not be updated
	if game.LastModified.After(before) {
		t.Errorf("Last modified should not be updated")
	}

	if game.Status != Finished {
		t.Error("The game should have the status", Finished)
	}
}
