module ManuRenderer = {
  open Console.List

  let promptUserName = () => {
    Console.Input.prompt(
      ~message="What's your nickname?",
      ~validate=value => {
        if value->Nickname.validate {
          Ok()
        } else {
          Error("Nickname is invalid")
        }
      },
      (),
    )
  }

  let promptGameCode = () => {
    Console.Input.prompt(
      ~message="Enter a code of the game you want to join. (Ask it from the creator of the game)",
      ~validate=value => {
        if value->Game.Code.validate {
          Ok()
        } else {
          Error("Game code is invalid")
        }
      },
      (),
    )
  }

  type choice = [#createGame | #joinGame | #exit]

  let make = () =>
    prompt(
      ~message="Game menu",
      ~choices=[
        Choice.make(~name="Create game", ~value=#createGame),
        Choice.make(~name="Join game", ~value=#joinGame),
        Choice.make(~name="Exit", ~value=#exit),
      ],
    )->Promise.then(answer => {
      switch answer {
      | #createGame =>
        promptUserName()->Promise.thenResolve(userName => Some(
          AppService.CreateGame({
            userName: userName,
          }),
        ))
      | #joinGame =>
        promptUserName()->Promise.then(userName => {
          promptGameCode()->Promise.thenResolve(gameCode => {
            Some(AppService.JoinGame({userName: userName, gameCode: gameCode}))
          })
        })
      | #exit => Js.Exn.raiseError("TODO: exit 0")
      }
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
    ->Promise.thenResolve(answer => {
      answer->Belt.Option.map(service->FSM.send)
    })
    ->ignore
  let _ = service->FSM.subscribe(state => {
    render(state)
  })
  render(service->FSM.getCurrentState)
}

run()
