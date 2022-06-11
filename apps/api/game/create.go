package game

func (s *gameStorer) CreateGame(player1Name string) uint {
	game := newGame()
	game.Player1.Name = player1Name

	// store game
	s.lastGameID++
	s.games[s.lastGameID] = game

	return s.lastGameID
}
