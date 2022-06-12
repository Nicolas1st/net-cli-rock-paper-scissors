module JoinGamePort: {
  type t = (~nickname: Nickname.t, ~gameCode: Game.Code.t) => Promise.t<unit>
}

module CreateGamePort: {
  type data = {gameCode: Game.Code.t}
  type t = (~nickname: Nickname.t) => Promise.t<data>
}

module SendMovePort: {
  type t = (~nickname: Nickname.t, ~gameCode: Game.Code.t, ~move: Game.Move.t) => Promise.t<unit>
}

module RequestGameStatusPort: {
  type data =
    | WaitingForOpponentJoin
    | InProgress
    | Finished(Game.finishedContext)
  type t = (~nickname: Nickname.t, ~gameCode: Game.Code.t) => Promise.t<data>
}

module GameMachine: {
  type state =
    | Loading
    | Status(Game.status)
  type event = OnGameStatus(RequestGameStatusPort.data) | SendMove(Game.Move.t)
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

let make: (
  ~createGame: CreateGamePort.t,
  ~joinGame: JoinGamePort.t,
  ~requestGameStatus: RequestGameStatusPort.t,
  ~sendMove: SendMovePort.t,
) => FSM.service<state, event>
