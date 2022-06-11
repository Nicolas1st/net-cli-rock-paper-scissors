package game

type gameStorer struct {
	lastGameID uint
	games      map[uint]*Game
}

func NewGameStorer() *gameStorer {
	return &gameStorer{
		lastGameID: 0,
		games:      map[uint]*Game{},
	}
}
