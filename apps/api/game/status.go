package game

type GameStatus string

const (
	Waiting   GameStatus = "waiting"
	InProcess GameStatus = "in process"
	Finished  GameStatus = "finished"
)
