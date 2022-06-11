package game

type GameStatus string

const (
	Waiting   GameStatus = "waiting"
	InProcess GameStatus = "inProcess"
	Finished  GameStatus = "finished"
)
