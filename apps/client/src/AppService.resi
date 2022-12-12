module GameMachine: {
  type state =
    | Loading
    | Status(Game.status)
  type event = OnGameStatus(Port.RequestGameStatus.data) | SendMove(Game.Move.t)
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
  ~createGame: Port.CreateGame.t,
  ~joinGame: Port.JoinGame.t,
  ~requestGameStatus: Port.RequestGameStatus.t,
  ~sendMove: Port.SendMove.t,
) => FSM.service<state, event>
