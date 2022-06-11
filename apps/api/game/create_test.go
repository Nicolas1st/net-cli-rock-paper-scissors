package game

import "testing"

func TestCreateGame(t *testing.T) {
	gs := NewGameStorer()
	playerName := "Nicolas"

	gameCode := gs.CreateGame(playerName)

	game, ok := gs.games[gameCode]
	if !ok {
		t.Error("Failed to create a game")
	}

	if game.Player1.Name != playerName {
		t.Error("The name of the player must be equall to " + playerName)
	}

	if game.Status != Waiting {
		t.Error("Just created game must have the status of waiting")
	}
}
