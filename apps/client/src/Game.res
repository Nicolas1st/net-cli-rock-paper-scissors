type outcome = Draw | Win | Loss
type move = Rock | Scissors | Paper
type status =
  | WaitingForPlayer
  | ReadyToPlay
  | WaitingForOpponentPlay
  | Finished({outcome: outcome, yourMove: move, opponentsMove: move})

module Code = {
  type t = string

  let validate = (self: t) => {
    self->Js.String2.trim !== ""
  }
}
