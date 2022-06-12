module Move: {
  type t = Rock | Scissors | Paper

  let values: array<t>
}

type outcome = Draw | Win | Loss
type finishedContext = {outcome: outcome, yourMove: Move.t, opponentsMove: Move.t}
type status =
  | WaitingForOpponentJoin
  | ReadyToPlay
  | WaitingForOpponentMove({yourMove: Move.t})
  | Finished(finishedContext)

module Code: {
  type t

  let fromString: string => option<t>

  let toString: t => string
}
