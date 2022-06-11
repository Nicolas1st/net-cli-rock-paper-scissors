package game

type Move string

const (
	Rock     Move = "rock"
	Paper    Move = "paper"
	Scissors Move = "scissors"
)

func findGameResult(playersMove, opponentsMove Move) gameResult {
	if playersMove == opponentsMove {
		return draw
	}

	if playersMove == Rock && opponentsMove == Scissors ||
		playersMove == Paper && opponentsMove == Rock ||
		playersMove == Scissors && opponentsMove == Paper {
		return win
	}

	return loss
}
