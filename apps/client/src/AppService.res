module JoinGamePort = {
  type t = (~nickname: Nickname.t, ~gameCode: Game.Code.t) => Promise.t<unit>
}

module CreateGamePort = {
  type data = {gameCode: Game.Code.t}
  type t = (~nickname: Nickname.t) => Promise.t<data>
}

module SendMovePort = {
  type t = (~nickname: Nickname.t, ~gameCode: Game.Code.t, ~move: Game.Move.t) => Promise.t<unit>
}

module RequestGameStatusPort = {
  type data =
    | WaitingForOpponentJoin
    | InProgress
    | Finished(Game.finishedContext)
  type t = (~nickname: Nickname.t, ~gameCode: Game.Code.t) => Promise.t<data>
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
  | CreatingGame({nickname: Nickname.t})
  | JoiningGame({nickname: Nickname.t, gameCode: Game.Code.t})
  | Game({nickname: Nickname.t, gameCode: Game.Code.t, gameState: GameMachine.state})
  | Exiting
type event =
  | CreateGame({nickname: Nickname.t})
  | OnCreateGameSuccess({gameCode: Game.Code.t})
  | JoinGame({nickname: Nickname.t, gameCode: Game.Code.t})
  | OnJoinGameSuccess
  | GameEvent(GameMachine.event)
  | Exit

let machine = FSM.make(~reducer=(~state, ~event) => {
  switch (state, event) {
  | (_, Exit) if state != Exiting => Exiting
  | (Menu, CreateGame({nickname})) => CreatingGame({nickname: nickname})
  | (CreatingGame({nickname}), OnCreateGameSuccess({gameCode})) =>
    Game({
      gameCode,
      nickname,
      gameState: GameMachine.machine->FSM.getInitialState,
    })
  | (Menu, JoinGame({nickname, gameCode})) => JoiningGame({nickname, gameCode})
  | (JoiningGame({gameCode, nickname}), OnJoinGameSuccess) =>
    Game({
      gameCode,
      nickname,
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

  let syncGameStatus = (~gameCode, ~nickname) => {
    requestGameStatus(~gameCode, ~nickname)
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
    | Game({nickname, gameCode}) =>
      switch maybeGameStatusSyncIntervalIdRef.contents {
      | Some(_) => ()
      | None => {
          syncGameStatus(~gameCode, ~nickname)
          maybeGameStatusSyncIntervalIdRef.contents = Some(Global.setInterval(() => {
              syncGameStatus(~gameCode, ~nickname)
            }, 3000))
        }
      }
    | _ => stopGameStatusSync()
    }
    switch state {
    | CreatingGame({nickname}) =>
      createGame(~nickname)
      ->Promise.thenResolve(({CreateGamePort.gameCode: gameCode}) => {
        service->FSM.send(OnCreateGameSuccess({gameCode: gameCode}))
      })
      ->ignore
    | JoiningGame({nickname, gameCode}) =>
      joinGame(~nickname, ~gameCode)
      ->Promise.thenResolve(() => {
        service->FSM.send(OnJoinGameSuccess)
      })
      ->ignore
    | Game({gameState: Status(WaitingForOpponentMove({yourMove})), nickname, gameCode}) =>
      sendMove(~gameCode, ~nickname, ~move=yourMove)->ignore
    | Exiting =>
      Global.queueMicrotask(() => {
        service->FSM.stop
      })
    | _ => ()
    }
  })
  service
}
