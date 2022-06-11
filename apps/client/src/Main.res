let run = () => {
  let service = AppService.make(~createGame=Api.CreateGame.call, ~joinGame=Api.JoinGame.call)

  let _ = service->FSM.subscribe(state => {
    Js.log2("STATE", state)
  })

  service->FSM.send(AppService.CreateGame({userName: "Dmitry"}))
}

run()
