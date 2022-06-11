package game

import "errors"

type result struct {
	Outcome       gameResult
	YourMove      Move
	OpponentsMove Move
}

func (s *gameStorer) GetGameStatus(gameCode uint, username string) (gameStatus, result, error) {
	var res result

	game, ok := s.games[gameCode]
	if !ok {
		return Waiting, res, errors.New("does not exist")
	}

	if game.Status == Finished {
		switch username {
		case game.Player1.Name:
			res.YourMove = game.Player1.Move
			res.OpponentsMove = game.Player2.Move
		case game.Player2.Name:
			res.YourMove = game.Player2.Move
			res.OpponentsMove = game.Player1.Move
		default:
			return game.Status, res, errors.New("can not get status for the third player")
		}
	}

	res.Outcome = findGameResult(res.YourMove, res.OpponentsMove)

	return game.Status, res, nil
}
