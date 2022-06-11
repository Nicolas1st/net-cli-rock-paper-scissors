module ManuRenderer = {
  open Console.List

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
      }->Some
    })
}

module CreatingGameRenderer = {
  let make = () => {
    Console.message("Creating game...")
    Promise.resolve(None)
  }
}

let rec renderer = (appState: AppService.state) => {
  switch appState {
  | Menu => ManuRenderer.make()
  | CreatingGame(_) => CreatingGameRenderer.make()
  | _ =>
    Console.Confirm.prompt(
      ~message=`Unknown state, do you want to exit? (${appState->Js.Json.serializeExn})`,
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
  let render = state' =>
    renderer(state')
    ->Promise.thenResolve(answer => answer->Belt.Option.map(service->FSM.send))
    ->ignore
  let _ = service->FSM.subscribe(state => {
    render(state)
  })
  render(service->FSM.getCurrentState)
}

run()
