package model

type Move string
type status string

const (
	None     Move = "none"
	Rock     Move = "rock"
	Paper    Move = "paper"
	Scissors Move = "scissors"
)

const (
	Waiting  status = "waiting"
	Idle     status = "idle"
	Finished status = "finished"
)

type Player struct {
	Name string
	Move Move
}

type Game struct {
	Status  status
	Player1 Player
	Player2 Player
}

func newGame() *Game {
	return &Game{
		Status:  Waiting,
		Player1: Player{},
		Player2: Player{},
	}
}
