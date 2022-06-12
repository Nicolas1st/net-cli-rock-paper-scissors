module JoinGamePort = {
  type t = (~userName: string, ~gameCode: string) => Promise.t<unit>
}

module CreateGamePort = {
  type data = {gameCode: string}
  type t = (~userName: string) => Promise.t<data>
}

module SendMovePort = {
  type t = (~userName: string, ~gameCode: string, ~move: Game.Move.t) => Promise.t<unit>
}

module RequestGameStatusPort = {
  type data =
    | WaitingForOpponentJoin
    | InProgress
    | Finished(Game.finishedContext)
  type t = (~userName: string, ~gameCode: string) => Promise.t<data>
}

module GameMachine = {
  type state =
    | Loading
    | Status(Game.status)
  type event = OnGameStatus(RequestGameStatusPort.data) | SendMove(Game.Move.t)

  let machine = FSM.make(~reducer=(~state, ~event) => {
    switch (state, event) {
    | (Status(WaitingForOpponentMove(_)), OnGameStatus(InProgress)) => state
    | (Status(ReadyToPlay), SendMove(move)) => Status(WaitingForOpponentMove({yourMove: move}))
    | (_, OnGameStatus(gameStatusData)) =>
      let remoteGameStatus: Game.status = switch gameStatusData {
      | WaitingForOpponentJoin => WaitingForOpponentJoin
      | InProgress => ReadyToPlay
      | Finished(context) => Finished(context)
      }
      switch state {
      | Loading => Status(remoteGameStatus)
      | Status(currentGameStatus) if currentGameStatus != remoteGameStatus =>
        Status(remoteGameStatus)
      | _ => state
      }
    | (_, _) => state
    }
  }, ~initialState=Loading)
}

type state =
  | Menu
  | CreatingGame({userName: string})
  | JoiningGame({userName: string, gameCode: string})
  | Game({userName: string, gameCode: string, gameState: GameMachine.state})
  | Exiting
type event =
  | CreateGame({userName: string})
  | OnCreateGameSuccess({gameCode: string})
  | JoinGame({userName: string, gameCode: string})
  | OnJoinGameSuccess
  | GameEvent(GameMachine.event)
  | Exit

let machine = FSM.make(~reducer=(~state, ~event) => {
  switch (state, event) {
  | (_, Exit) if state != Exiting => Exiting
  | (Menu, CreateGame({userName})) => CreatingGame({userName: userName})
  | (CreatingGame({userName}), OnCreateGameSuccess({gameCode})) =>
    Game({
      gameCode: gameCode,
      userName: userName,
      gameState: GameMachine.machine->FSM.getInitialState,
    })
  | (Menu, JoinGame({userName, gameCode})) => JoiningGame({userName: userName, gameCode: gameCode})
  | (JoiningGame({gameCode, userName}), OnJoinGameSuccess) =>
    Game({
      gameCode: gameCode,
      userName: userName,
      gameState: GameMachine.machine->FSM.getInitialState,
    })
  | (Game(gameContext), GameEvent(gameEvent)) =>
    let prevGameState = gameContext.gameState
    let nextGameState = GameMachine.machine->FSM.transition(~state=prevGameState, ~event=gameEvent)
    if nextGameState != prevGameState {
      Game({
        ...gameContext,
        gameState: nextGameState,
      })
    } else {
      state
    }
  | (_, _) => state
  }
}, ~initialState=Menu)

let make = (
  ~createGame: CreateGamePort.t,
  ~joinGame: JoinGamePort.t,
  ~requestGameStatus: RequestGameStatusPort.t,
  ~sendMove: SendMovePort.t,
) => {
  let service = machine->FSM.interpret
  let maybeGameStatusSyncIntervalIdRef = ref(None)

  let syncGameStatus = (~gameCode, ~userName) => {
    requestGameStatus(~gameCode, ~userName)
    ->Promise.thenResolve(data => {
      service->FSM.send(GameEvent(OnGameStatus(data)))
    })
    ->ignore
  }
  let stopGameStatusSync = () => {
    switch maybeGameStatusSyncIntervalIdRef.contents {
    | Some(gameStatusSyncIntervalId) => Global.clearInterval(gameStatusSyncIntervalId)
    | None => ()
    }
  }

  let _ = service->FSM.subscribe(state => {
    switch state {
    | Game({gameState: Status(Finished(_))}) => stopGameStatusSync()
    | Game({userName, gameCode}) =>
      switch maybeGameStatusSyncIntervalIdRef.contents {
      | Some(_) => ()
      | None => {
          syncGameStatus(~gameCode, ~userName)
          maybeGameStatusSyncIntervalIdRef.contents = Some(Global.setInterval(() => {
              syncGameStatus(~gameCode, ~userName)
            }, 3000))
        }
      }
    | _ => stopGameStatusSync()
    }
    switch state {
    | CreatingGame({userName}) =>
      createGame(~userName)
      ->Promise.thenResolve(({CreateGamePort.gameCode: gameCode}) => {
        service->FSM.send(OnCreateGameSuccess({gameCode: gameCode}))
      })
      ->ignore
    | JoiningGame({userName, gameCode}) =>
      joinGame(~userName, ~gameCode)
      ->Promise.thenResolve(() => {
        service->FSM.send(OnJoinGameSuccess)
      })
      ->ignore
    | Game({gameState: Status(WaitingForOpponentMove({yourMove})), userName, gameCode}) =>
      sendMove(~gameCode, ~userName, ~move=yourMove)->ignore
    | Exiting =>
      Global.queueMicrotask(() => {
        service->FSM.stop
      })
    | _ => ()
    }
  })
  service
}
