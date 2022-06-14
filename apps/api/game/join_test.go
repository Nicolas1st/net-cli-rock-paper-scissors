package game

import "testing"

func TestJoinGame(t *testing.T) {
	gs := NewGameStorer()
	player1Name := "Player1"
	player2Name := "Player2"

	// create game
	gameCode, game, gameWasCreated := setupGame(gs, player1Name, player2Name)
	if !gameWasCreated {
		t.Error("The game should exist")
	}

	// check for not existent game
	if err := gs.JoinGame(gameCode+1, player2Name); err == nil {
		t.Error("Should return an error because the game does not exist")
	}

	// check second player join
	before := game.LastModified
	if err := gs.JoinGame(gameCode, player2Name); err != nil {
		t.Error("Player 2 should be able to join the game")
	}

	if game.Status != InProcess {
		t.Error("The game must have the statuts ", InProcess)
	}

	// should be modified after join
	if !game.LastModified.After(before) {
		t.Error("Last modified field must be updated after game join happens")
	}

	// check first player rejoin
	before = game.LastModified
	if err := gs.JoinGame(gameCode, player1Name); err != nil {
		t.Error("Player 1 should be able to rejoin the game")
	}

	// should not be modified after rejoin
	if game.LastModified.After(before) {
		t.Error("Last modified field should not be updated after game rejoin happens")
	}

	// check second player rejoin
	before = game.LastModified
	if err := gs.JoinGame(gameCode, player2Name); err != nil {
		t.Error("Player 2 should be able to rejoin the game")
	}

	// should not be modified after rejoin
	if game.LastModified.After(before) {
		t.Error("Last modified field should not be updated after game rejoin happens")
	}

	// check 3rd player join
	before = game.LastModified
	thirdPlayerNotUsedName := player1Name + "3"
	if err := gs.JoinGame(gameCode, thirdPlayerNotUsedName); err == nil {
		t.Error("Should not allow for the 3rd player to join the game")
	}

	// should not be modified after join attempt
	if game.LastModified.After(before) {
		t.Error("Last modified field should not be updated after failed game join")
	}
}
