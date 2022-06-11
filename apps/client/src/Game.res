module Move = {
  type t = Rock | Scissors | Paper

  let values = [Rock, Scissors, Paper]
}

type outcome = Draw | Win | Loss
type finishedContext = {outcome: outcome, yourMove: Move.t, opponentsMove: Move.t}
type status =
  | WaitingForOpponentJoin
  | ReadyToPlay
  | WaitingForOpponentMove({yourMove: Move.t})
  | Finished(finishedContext)

module Code = {
  type t = string

  let validate = (self: t) => {
    self->Js.String2.trim !== ""
  }
}
