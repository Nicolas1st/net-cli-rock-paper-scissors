package game

import (
	"testing"
	"time"
)

func TestRemoveAbandonedGames(t *testing.T) {
	gs := NewGameStorer()
	player1Name := "player1"
	player2Name := "player2"

	gameCode, _, wasCreated := setupGame(gs, player1Name, player2Name)
	if !wasCreated {
		t.Error("Failed to create the game")
	}
	gs.JoinGame(gameCode, player2Name)

	// check game exists
	if _, ok := gs.games[gameCode]; !ok {
		t.Error("The game must exist before testing")
	}

	// check does not exist after one second since it was modified
	removeTimePeriod := time.Second
	time.Sleep(removeTimePeriod)

	gs.RemoveAbandonedGames(removeTimePeriod)

	if _, ok := gs.games[gameCode]; ok {
		t.Error("Must have removed the game after the max inaction time period")
	}
}
