type outcome = Draw | Win | Loss
type move = Rock | Scissors | Paper
type finishedContext = {outcome: outcome, yourMove: move, opponentsMove: move}
type status =
  | WaitingForOpponentJoin
  | ReadyToPlay
  | WaitingForOpponentMove({yourMove: move})
  | Finished(finishedContext)

module Code = {
  type t = string

  let validate = (self: t) => {
    self->Js.String2.trim !== ""
  }
}
