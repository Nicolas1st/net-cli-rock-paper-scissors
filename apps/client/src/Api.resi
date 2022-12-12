module CreateGame: {
  let make: unit => Port.CreateGame.t
}

module JoinGame: {
  let make: unit => Port.JoinGame.t
}

module RequestGameStatus: {
  let make: unit => Port.RequestGameStatus.t
}

module SendMove: {
  let make: unit => Port.SendMove.t
}
