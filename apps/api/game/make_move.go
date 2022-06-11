package game

import "errors"

func (s *gameStorer) MakeMove(gameCode uint, playerName string, move Move) error {
	if move != Rock && move != Paper && move != Scissors {
		return errors.New("impossible move")
	}

	game, ok := s.games[gameCode]
	if !ok {
		return errors.New("does not exist")
	}

	if game.Status != InProcess {
		return errors.New("it's possible to make moves only if the is still going")
	}

	// store the move if it has not been done yet
	switch playerName {
	case game.Player1.Name:
		if game.Player1.Move != Empty {
			return errors.New("the move was already made")
		}
		game.Player1.Move = move
	case game.Player2.Name:
		if game.Player2.Move != Empty {
			return errors.New("the move was already made")
		}
		game.Player2.Move = move
	default:
		return errors.New("the user with this name does not exist")
	}

	// change game status all moves were made
	if game.Player1.Move != Empty && game.Player2.Move != Empty {
		game.Status = Finished
	}

	return nil
}
