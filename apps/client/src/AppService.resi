module JoinGamePort: {
  type t = (~userName: string, ~gameCode: string) => Promise.t<unit>
}

module CreateGamePort: {
  type data = {gameCode: string}
  type t = (~userName: string) => Promise.t<data>
}

module SendMovePort: {
  type t = (~userName: string, ~gameCode: string, ~move: Game.Move.t) => Promise.t<unit>
}

module RequestGameStatusPort: {
  type data =
    | WaitingForOpponentJoin
    | InProgress
    | Finished(Game.finishedContext)
  type t = (~userName: string, ~gameCode: string) => Promise.t<data>
}

module GameMachine: {
  type state =
    | Loading
    | Status(Game.status)
  type event = OnGameStatus(RequestGameStatusPort.data) | SendMove(Game.Move.t)
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

let make: (
  ~createGame: CreateGamePort.t,
  ~joinGame: JoinGamePort.t,
  ~requestGameStatus: RequestGameStatusPort.t,
  ~sendMove: SendMovePort.t,
) => FSM.service<state, event>
