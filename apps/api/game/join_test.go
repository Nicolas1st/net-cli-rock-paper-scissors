package game

import "testing"

func TestJoinGame(t *testing.T) {
	gs := NewGameStorer()
	player1Name := "Player1"
	player2Name := "Player2"

	// add game
	gameCode := gs.CreateGame(player1Name)

	// the game should not exist
	if err := gs.JoinGame(gameCode+1, player2Name); err == nil {
		t.Error("Should return an error because the game does not exist")
	}

	// can not have the same name as the other player
	if err := gs.JoinGame(gameCode, player1Name); err == nil {
		t.Error("Should return an error because the game does not exist")
	}

	// shoud join the game
	if err := gs.JoinGame(gameCode, player2Name); err != nil {
		t.Error("Should be able to join")
	}

	// the game should exist
	game, ok := gs.games[gameCode]
	if !ok {
		t.Error("The game should exist")
	}

	if game.Player2.Name != player2Name {
		t.Error("The second user must have the name of ", player2Name)
	}

	if game.Status != InProcess {
		t.Error("The game must have the statuts ", InProcess)
	}
}
