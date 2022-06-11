package model

import "errors"

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

func (s *gameStorer) CreateGame(player1Name string) uint {
	// create game for player 1
	game := newGame()
	game.Player1.Name = player1Name

	// store game
	s.lastGameID++
	s.games[s.lastGameID] = game

	return s.lastGameID
}

func (s *gameStorer) JoinGame(gameCode uint, player2Name string) error {
	game, ok := s.games[gameCode]
	if !ok {
		return errors.New("does not exist")
	}

	game.Player2.Name = player2Name
	game.Status = Idle

	return nil
}

func (s *gameStorer) MakeMove(gameCode uint, playerName string, move Move) error {
	game, ok := s.games[gameCode]
	if !ok {
		return errors.New("does not exist")
	}

	switch playerName {
	case game.Player1.Name:
		game.Player1.Move = move
		game.Status = Idle
	case game.Player2.Name:
		game.Player2.Move = move
		game.Status = Finished
	case game.Player2.Name:
		return errors.New("does not exist")
	}

	return nil
}

func (s *gameStorer) GetGame(gameCode uint) (*Game, error) {
	game, ok := s.games[gameCode]
	if !ok {
		return game, errors.New("does not exist")
	}

	return game, nil
}
