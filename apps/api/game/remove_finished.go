package game

func (s *gameStorer) RemoveFinishedGames() {
	for code, g := range s.games {
		if g.Status == Finished {
			delete(s.games, code)
		}
	}
}
