package game

import "errors"

func (s *gameStorer) JoinGame(gameCode uint, player2Name string) error {
	game, ok := s.games[gameCode]
	if !ok {
		return errors.New("does not exist")
	}

	if player2Name == game.Player1.Name {
		return errors.New("name is already occupied")
	}

	game.Player2.Name = player2Name
	game.Status = InProcess

	return nil
}
