package game

type Game struct {
	Status  GameStatus
	Player1 Player
	Player2 Player
}

type Player struct {
	Name string
	Move Move
}

func newGame() *Game {
	return &Game{
		Status: Waiting,
		Player1: Player{
			Move: Empty,
		},
		Player2: Player{
			Move: Empty,
		},
	}
}
