let run = () => {
  let service = AppService.make(~createGame=Api.CreateGame.call, ~joinGame=Api.JoinGame.call)

  let _ = service->FSM.subscribe(state => {
    let messge = switch state {
    | Menu => "Menu"
    | CreatingGame({userName}) => `CreatingGame {userName: "${userName}"}`
    | JoiningGame({userName, gameCode}) =>
      `JoiningGame {userName: "${userName}", gameCode: "${gameCode}"}`
    | Game(gameService) => {
        let gameState = gameService->FSM.getCurrentState
        `Game {userName: "${gameState.userName}", gameCode: "${gameState.gameCode}"}`
      }
    }
    Js.log2("Enter new state", messge)
  })

  service->FSM.send(AppService.CreateGame({userName: "Dmitry"}))
}

run()
