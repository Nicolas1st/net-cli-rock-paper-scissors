package game

import "time"

// RemoveAbandonedGames - removes all games that were not updated in a while
func (s *gameStorer) RemoveAbandonedGames(removeInterval time.Duration) {
	for code, g := range s.games {
		if time.Now().After(g.CreatedAt.Add(removeInterval)) {
			delete(s.games, code)
		}
	}
}
