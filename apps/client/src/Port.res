module JoinGame = {
  type input = {nickname: Nickname.t, gameCode: Game.Code.t}
  type t = input => Promise.t<unit>
}

module CreateGame = {
  type input = {nickname: Nickname.t}
  type data = {gameCode: Game.Code.t}
  type t = input => Promise.t<data>
}

module SendMove = {
  type input = {nickname: Nickname.t, gameCode: Game.Code.t, yourMove: Game.Move.t}
  type t = input => Promise.t<unit>
}

module RequestGameStatus = {
  type input = {nickname: Nickname.t, gameCode: Game.Code.t}
  type data =
    | WaitingForOpponentJoin
    | InProgress
    | Finished(Game.finishedContext)
  type t = input => Promise.t<data>
}
