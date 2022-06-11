let run = () => {
  let service = AppService.make(~createGame=Api.CreateGame.call, ~joinGame=(
    ~userName as _,
    ~gameCode as _,
  ) => {
    Js.Exn.raiseError("Not implemented")
  })

  let _ = service->FSM.subscribe(state => {
    Js.log2("STATE", state)
  })

  service->FSM.send(AppService.CreateGame({userName: "Dmitry"}))
}

run()
