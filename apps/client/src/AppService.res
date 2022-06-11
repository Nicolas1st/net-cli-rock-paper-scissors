module JoinGamePort = {
  type t = (~userName: string, ~gameCode: string) => Promise.t<result<unit, unit>>
}

module CreateGamePort = {
  type data = {gameCode: string}
  type t = (~userName: string) => Promise.t<result<data, unit>>
}

module RequestGameStatusPort = {
  type data = Game.status
  type t = (~userName: string, ~gameCode: string) => Promise.t<result<data, unit>>
}

module GameMachine = {
  type state =
    | Loading
    | Status(Game.status)
  type event = OnGameStatus(Game.status)

  let machine = FSM.make(~reducer=(~state, ~event) => {
    switch (state, event) {
    | (Loading, OnGameStatus(status)) => Status(status)
    | (Status(currentStatus), OnGameStatus(status)) if currentStatus != status => Status(status)
    | (_, _) => state
    }
  }, ~initialState=Loading)
}

type state =
  | Menu
  | CreatingGame({userName: string})
  | JoiningGame({userName: string, gameCode: string})
  | Game({userName: string, gameCode: string, gameState: GameMachine.state})
type event =
  | CreateGame({userName: string})
  | OnCreateGameSuccess({gameCode: string})
  | OnCreateGameFailure
  | JoinGame({userName: string, gameCode: string})
  | OnJoinGameSuccess
  | OnJoinGameFailure
  | GameEvent(GameMachine.event)

let machine = FSM.make(~reducer=(~state, ~event) => {
  switch (state, event) {
  | (Menu, CreateGame({userName})) => CreatingGame({userName: userName})
  | (CreatingGame({userName}), OnCreateGameSuccess({gameCode})) =>
    Game({
      gameCode: gameCode,
      userName: userName,
      gameState: GameMachine.machine->FSM.getInitialState,
    })
  | (CreatingGame(_), OnCreateGameFailure) => Menu
  | (Menu, JoinGame({userName, gameCode})) => JoiningGame({userName: userName, gameCode: gameCode})
  | (JoiningGame({gameCode, userName}), OnJoinGameSuccess) =>
    Game({
      gameCode: gameCode,
      userName: userName,
      gameState: GameMachine.machine->FSM.getInitialState,
    })
  | (JoiningGame(_), OnJoinGameFailure) => Menu
  | (Game(gameContext), GameEvent(gameEvent)) =>
    Game({
      ...gameContext,
      gameState: GameMachine.machine->FSM.transition(
        ~state=gameContext.gameState,
        ~event=gameEvent,
      ),
    })
  | (_, _) => state
  }
}, ~initialState=Menu)

let make = (
  ~createGame: CreateGamePort.t,
  ~joinGame: JoinGamePort.t,
  ~requestGameStatus: RequestGameStatusPort.t,
) => {
  let service = machine->FSM.interpret
  let _ = service->FSM.subscribe(state => {
    switch state {
    | CreatingGame({userName}) =>
      createGame(~userName)
      ->Promise.thenResolve(result => {
        switch result {
        | Ok({CreateGamePort.gameCode: gameCode}) =>
          service->FSM.send(OnCreateGameSuccess({gameCode: gameCode}))
        | Error() => service->FSM.send(OnCreateGameFailure)
        }
      })
      ->ignore
    | JoiningGame({userName, gameCode}) =>
      joinGame(~userName, ~gameCode)
      ->Promise.thenResolve(result => {
        switch result {
        | Ok() => service->FSM.send(OnJoinGameSuccess)
        | Error() => service->FSM.send(OnJoinGameFailure)
        }
      })
      ->ignore
    | Game({gameState: Loading, userName, gameCode}) =>
      requestGameStatus(~gameCode, ~userName)
      ->Promise.thenResolve(result => {
        switch result {
        | Ok(data) => service->FSM.send(GameEvent(OnGameStatus(data)))
        | Error() => Js.Exn.raiseError("Smth went wrong")
        }
      })
      ->ignore
    | _ => ()
    }
  })
  service
}
