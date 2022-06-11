module Port = {
  module JoinGame = {
    type t = (~userName: string, ~gameCode: string) => Promise.t<result<unit, unit>>
  }

  module CreateGame = {
    type data = {gameCode: string}
    type t = (~userName: string) => Promise.t<result<data, unit>>
  }
}

type state =
  | Menu
  | CreatingGame({userName: string})
  | JoiningGame({userName: string, gameCode: string})
  | Game(GameService.t)
type event =
  | CreateGame({userName: string})
  | OnCreateGameSuccess(GameService.t)
  | OnCreateGameFailure
  | JoinGame({userName: string, gameCode: string})
  | OnJoinGameSuccess(GameService.t)
  | OnJoinGameFailure

let machine = FSM.make(~reducer=(~state, ~event) => {
  switch (state, event) {
  | (Menu, CreateGame({userName})) => CreatingGame({userName: userName})
  | (CreatingGame(_), OnCreateGameSuccess(gameService)) => Game(gameService)
  | (CreatingGame(_), OnCreateGameFailure) => Menu
  | (Menu, JoinGame({userName, gameCode})) => JoiningGame({userName: userName, gameCode: gameCode})
  | (JoiningGame(_), OnJoinGameSuccess(gameService)) => Game(gameService)
  | (JoiningGame(_), OnJoinGameFailure) => Menu
  | (_, _) => state
  }
}, ~initialState=Menu)

let make = (~createGame: Port.CreateGame.t, ~joinGame: Port.JoinGame.t) => {
  let service = machine->FSM.interpret
  let _ = service->FSM.subscribe(state => {
    switch state {
    | CreatingGame({userName}) =>
      createGame(~userName)
      ->Promise.thenResolve(result => {
        switch result {
        | Ok({Port.CreateGame.gameCode: gameCode}) =>
          service->FSM.send(OnCreateGameSuccess(GameService.make(~gameCode, ~userName)))
        | Error() => service->FSM.send(OnCreateGameFailure)
        }
      })
      ->ignore
    | JoiningGame({userName, gameCode}) =>
      joinGame(~userName, ~gameCode)
      ->Promise.thenResolve(result => {
        switch result {
        | Ok() => service->FSM.send(OnJoinGameSuccess(GameService.make(~gameCode, ~userName)))
        | Error() => service->FSM.send(OnJoinGameFailure)
        }
      })
      ->ignore
    | _ => ()
    }
  })
  service
}
