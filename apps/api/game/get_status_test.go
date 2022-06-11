package game

import "testing"

func TestGetStatus(t *testing.T) {
	gs := NewGameStorer()
	player1Name := "player1"
	player2Name := "player2"
	player1Move := Paper
	player2Move := Rock

	gameCode := gs.CreateGame(player1Name)
	// should have the waiting status
	if status, _, err := gs.GetGameStatus(gameCode, player1Name); status != Waiting || err != nil {
		t.Error("There should be no errors after game creation and the status must be", Waiting)
	}

	gs.JoinGame(gameCode, player2Name)
	// should have the inProcess status
	if status, _, err := gs.GetGameStatus(gameCode, player1Name); status != InProcess || err != nil {
		t.Error("There should be no errors after game creation and the status must be", InProcess)
	}

	gs.MakeMove(gameCode, player1Name, player1Move)
	if status, _, err := gs.GetGameStatus(gameCode, player1Name); status != InProcess || err != nil {
		t.Error("There should be no errors after making one move and the status should be", InProcess)
	}

	gs.MakeMove(gameCode, player2Name, player2Move)
	status, res, err := gs.GetGameStatus(gameCode, player1Name)
	if status != Finished || err != nil {
		t.Error("There should be no errors after making the second move and the status should be", Finished)
	}

	if res.Outcome != win {
		t.Errorf("Did not set the status for the game when it's finished")
	}

	if res.YourMove != player1Move || res.OpponentsMove != player2Move {
		t.Error("Wrong moves")
	}

	_, res, _ = gs.GetGameStatus(gameCode, player2Name)
	if res.Outcome != loss {
		t.Log(res.Outcome)
		t.Errorf("Wrong status for player2")
	}
}
