let moveToText = (move: Game.Move.t) =>
  switch move {
  | Rock => `Rock 🪨`
  | Scissors => `Scissors ✂️`
  | Paper => `Paper 📄`
  }

module ManuRenderer = {
  open UI.List

  let promptUserName = () => {
    UI.Input.prompt(
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
    UI.Input.prompt(
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
      | #exit => Some(AppService.Exit)->Promise.resolve
      }
    })
}

module CreatingGameRenderer = {
  let make = () => {
    UI.message("Creating game...")
    Promise.resolve(None)
  }
}

module JoiningGameRenderer = {
  let make = () => {
    UI.message("Joining game...")
    Promise.resolve(None)
  }
}

module GameLoadingRenderer = {
  let make = () => {
    UI.message("Loading game...")
    Promise.resolve(None)
  }
}

module GameStatusWaitingForOpponentJoinRenderer = {
  let make = () => {
    UI.message("Waiting when an opponent join the game...")
    Promise.resolve(None)
  }
}

module GameStatusWaitingForOpponentMoveRenderer = {
  let make = (~yourMove: Game.Move.t) => {
    UI.message(
      [
        "Waiting for the opponent move...",
        `Your move: ${yourMove->moveToText}`,
      ]->UI.MultilineText.make,
    )
    Promise.resolve(None)
  }
}

module GameStatusReadyToPlayRenderer = {
  open UI.List

  let make = () =>
    prompt(
      ~message="What's your move?",
      ~choices=Game.Move.values->Js.Array2.map(move =>
        Choice.make(~name=move->moveToText, ~value=move)
      ),
    )->Promise.thenResolve(answer => {
      Some(AppService.GameEvent(AppService.GameMachine.SendMove(answer)))
    })
}

module GameStatusFinishedRenderer = {
  let make = (~outcome: Game.outcome, ~yourMove, ~opponentsMove) => {
    let outcomeText = switch outcome {
    | Win => `You won 🏆`
    | Draw => `Draw 🤝`
    | Loss => `You lost 🪦`
    }

    UI.message(
      [
        "Game finished!",
        `Outcome: ${outcomeText}`,
        `Your move: ${yourMove->moveToText}`,
        `Opponent's move: ${opponentsMove->moveToText}`,
      ]->UI.MultilineText.make,
    )
    Promise.resolve(None)
  }
}

let renderer = (appState: AppService.state) => {
  switch appState {
  | Menu => ManuRenderer.make()
  | CreatingGame(_) => CreatingGameRenderer.make()
  | JoiningGame(_) => JoiningGameRenderer.make()
  | Game({gameState: Loading}) => GameLoadingRenderer.make()
  | Game({gameState: Status(WaitingForOpponentJoin)}) =>
    GameStatusWaitingForOpponentJoinRenderer.make()
  | Game({gameState: Status(ReadyToPlay)}) => GameStatusReadyToPlayRenderer.make()
  | Game({gameState: Status(WaitingForOpponentMove({yourMove}))}) =>
    GameStatusWaitingForOpponentMoveRenderer.make(~yourMove)
  | Game({gameState: Status(Finished({outcome, yourMove, opponentsMove}))}) =>
    GameStatusFinishedRenderer.make(~outcome, ~yourMove, ~opponentsMove)
  | Exiting => %raw(`process.exit(0)`)
  }
}

let run = () => {
  let service = AppService.make(
    ~createGame=Api.CreateGame.call,
    ~joinGame=Api.JoinGame.call,
    ~requestGameStatus=Api.RequestGameStatus.call,
    ~sendMove=Api.SendMove.call,
  )
  // let service = AppService.make(
  //   ~createGame=(~userName as _) => {
  //     Promise.resolve({AppService.CreateGamePort.gameCode: "1234"})
  //   },
  //   ~joinGame=(~userName as _, ~gameCode as _) => {
  //     Promise.resolve()
  //   },
  //   ~requestGameStatus=(~userName as _, ~gameCode as _) => {
  //     Promise.resolve(
  //       AppService.RequestGameStatusPort.Finished({
  //         outcome: Win,
  //         yourMove: Rock,
  //         opponentsMove: Scissors,
  //       }),
  //     )
  //   },
  //   ~sendMove=(~userName as _, ~gameCode as _, ~move as _) => {
  //     Promise.resolve()
  //   },
  // )
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
