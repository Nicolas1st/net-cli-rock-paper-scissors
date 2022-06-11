type outcome = Draw | Win | Loss
type move = Rock | Scissors | Paper
type status =
  | WaitingForPlayer
  | ReadyToPlay
  | WaitingForOpponentPlay
  | Finished({outcome: outcome, yourMove: move, opponentsMove: move})
