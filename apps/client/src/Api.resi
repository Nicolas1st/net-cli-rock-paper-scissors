module CreateGame: {
  let call: AppService.CreateGamePort.t
}

module JoinGame: {
  let call: AppService.JoinGamePort.t
}

module RequestGameStatus: {
  let call: AppService.RequestGameStatusPort.t
}

module SendMove: {
  let call: AppService.SendMovePort.t
}
