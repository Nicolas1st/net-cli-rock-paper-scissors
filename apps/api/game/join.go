package game

import (
	"errors"
)

func (s *gameStorer) JoinGame(gameCode uint, playerName string) error {
	game, ok := s.games[gameCode]
	if !ok {
		return errors.New("does not exist")
	}

	// join game if there is not second player yet
	// the first player is the player who has created the game
	if game.Player2.Name == "" {
		// second player joins the game
		game.Player2.Name = playerName
		game.UpdateLastModifiedTime()
		game.Status = InProcess
		return nil
	}

	// check if it's join or rejoin
	if game.Player1.Name == playerName || game.Player2.Name == playerName {
		// players a rejoining the game
		return nil
	} else {
		// the third player is trying to connect
		// to a 2 player game
		return errors.New("the third player is trying to connect")
	}
}
