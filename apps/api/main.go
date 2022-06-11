package main

import (
	"net/http"
	"time"

	"github.com/Nicolas1st/go-rs-rock-paper-scissors/handlers"
	"github.com/Nicolas1st/go-rs-rock-paper-scissors/model"
)

func checkForMethod(next http.HandlerFunc, method string) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		if r.Method != method {
			w.WriteHeader(http.StatusNotFound)
			return
		}

		next(w, r)
	}
}

func main() {
	gameStorer := model.NewGameStorer()
	gameController := handlers.NewGamesController(gameStorer)

	m := http.NewServeMux()
	m.HandleFunc("/game", checkForMethod(gameController.CreateGame, http.MethodPost))
	m.HandleFunc("/game/connection", checkForMethod(gameController.JoinGame, http.MethodPost))
	m.HandleFunc("/game/move", checkForMethod(gameController.MakeMove, http.MethodPost))
	m.HandleFunc("/game/status", checkForMethod(gameController.GetStatus, http.MethodGet))

	s := http.Server{
		Addr:         ":8880",
		Handler:      m,
		ReadTimeout:  time.Second,
		WriteTimeout: time.Second,
		IdleTimeout:  time.Second,
	}

	s.ListenAndServe()
}
