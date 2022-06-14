package game

func setupGame(gs *gameStorer, player1Name, player2Name string) (gameCode uint, g *Game, gameWasCreated bool) {
	gameCode = gs.CreateGame(player1Name)
	game, ok := gs.games[gameCode]

	return gameCode, game, ok
}
