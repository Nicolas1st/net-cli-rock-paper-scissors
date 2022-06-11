package game

type gameStatus string

const (
	Waiting   gameStatus = "waiting"
	InProcess gameStatus = "in process"
	Finished  gameStatus = "finished"
)
