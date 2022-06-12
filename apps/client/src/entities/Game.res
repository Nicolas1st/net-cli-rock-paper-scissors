module Move = {
  type t = Rock | Scissors | Paper

  let values = [Rock, Scissors, Paper]
}

module Code = {
  type t = string

  let fromString = string => {
    if string->Js.String2.trim !== "" {
      Some(string)
    } else {
      None
    }
  }

  let toString = Obj.magic
}

type outcome = Draw | Win | Loss
type finishedContext = {outcome: outcome, yourMove: Move.t, opponentsMove: Move.t}
type status =
  | WaitingForOpponentJoin
  | ReadyToPlay
  | WaitingForOpponentMove({yourMove: Move.t})
  | Finished(finishedContext)
