package game

import "time"

type Game struct {
	Status       GameStatus
	Player1      Player
	Player2      Player
	CreatedAt    time.Time
	LastModified time.Time
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
		CreatedAt:    time.Now(),
		LastModified: time.Now(),
	}
}

func (g *Game) UpdateLastModifiedTime() {
	g.LastModified = time.Now()
}
