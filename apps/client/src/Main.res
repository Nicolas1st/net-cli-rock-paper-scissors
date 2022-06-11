module ManuRenderer = {
  open Inquirer.List

  type choice = [#createGame | #joinGame | #exit]

  let make = () =>
    prompt(
      ~message="Game menu",
      ~choices=[
        Choice.make(~name="Create game", ~value=#createGame),
        Choice.make(~name="Join game", ~value=#joinGame),
        Choice.make(~name="Exit", ~value=#exit),
      ],
    )->Promise.thenResolve(answer => {
      switch answer {
      | #createGame => AppService.CreateGame({userName: "Hardcoded"})
      | #joinGame => AppService.JoinGame({userName: "Hardcoded", gameCode: "Hardcoded"})
      | #exit => Js.Exn.raiseError("TODO: exit 0")
      }
    })
}

let rec renderer = (appState: AppService.state) => {
  switch appState {
  | Menu => ManuRenderer.make()

  | _ =>
    Inquirer.Confirm.prompt(
      ~message="Unknown state, do you want to exit?",
    )->Promise.then(answer => {
      if answer {
        Js.Exn.raiseError("TODO: exit 0")
      } else {
        renderer(appState)
      }
    })
  }
}

let run = () => {
  let service = AppService.make(
    ~createGame=Api.CreateGame.call,
    ~joinGame=Api.JoinGame.call,
    ~requestGameStatus=Api.RequestGameStatus.call,
  )
  let render = state' => renderer(state')->Promise.thenResolve(service->FSM.send)->ignore
  let _ = service->FSM.subscribe(state => {
    render(state)
  })
  render(service->FSM.getCurrentState)
}

run()
