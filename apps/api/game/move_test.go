package game

import "testing"

type GameMoves struct {
	player   Move
	opponent Move
}

func TestDraw(t *testing.T) {
	tests := []GameMoves{
		{
			player:   Rock,
			opponent: Rock,
		},
		{
			player:   Paper,
			opponent: Paper,
		},
		{
			player:   Scissors,
			opponent: Scissors,
		},
	}

	for _, test := range tests {
		if res := findGameResult(test.player, test.opponent); res != draw {
			t.Errorf("The result must be draw for %s and %s, got %s", test.player, test.opponent, res)
		}
	}
}

func TestWin(t *testing.T) {
	tests := []GameMoves{
		{
			player:   Rock,
			opponent: Scissors,
		},
		{
			player:   Paper,
			opponent: Rock,
		},
		{
			player:   Scissors,
			opponent: Paper,
		},
	}

	for _, test := range tests {
		if res := findGameResult(test.player, test.opponent); res != win {
			t.Errorf("The result must be win for %s and %s, got %s", test.player, test.opponent, res)
		}
	}
}

func TestLoss(t *testing.T) {
	tests := []GameMoves{
		{
			player:   Rock,
			opponent: Paper,
		},
		{
			player:   Paper,
			opponent: Scissors,
		},
		{
			player:   Scissors,
			opponent: Rock,
		},
	}

	for _, test := range tests {
		if res := findGameResult(test.player, test.opponent); res != loss {
			t.Errorf("The result must be loss for %s and %s, got %s", test.player, test.opponent, res)
		}
	}
}
