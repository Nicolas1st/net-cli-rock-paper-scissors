let moveToText = (move: Game.Move.t) =>
  switch move {
  | Rock => `Rock 🪨`
  | Scissors => `Scissors ✂️`
  | Paper => `Paper 📄`
  }

module ManuRenderer = {
  open UI.List

  let promptNickname = () => {
    UI.Input.prompt(~message="What's your nickname?", ~parser=value => {
      switch value->Nickname.fromString {
      | Some(nickname) => Ok(nickname)
      | None => Error("Nickname is invalid")
      }
    })
  }

  let promptGameCode = () => {
    UI.Input.prompt(
      ~message=[
        "Enter a code of the game you want to join.",
        "(Ask it from the creator of the game)\n",
      ]->UI.MultilineText.make,
      ~parser=value => {
        switch value->Game.Code.fromString {
        | Some(gameCode) => Ok(gameCode)
        | None => Error("Game code is invalid")
        }
      },
    )
  }

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
        promptNickname()->Promise.thenResolve(nickname => Some(
          AppService.CreateGame({
            nickname: nickname,
          }),
        ))
      | #joinGame =>
        promptNickname()->Promise.then(nickname => {
          promptGameCode()->Promise.thenResolve(
            gameCode => {
              Some(
                AppService.JoinGame({
                  nickname,
                  gameCode,
                }),
              )
            },
          )
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
  let make = (~gameCode) => {
    UI.message(
      [
        "Waiting when an opponent joins the game...",
        `Game code: ${gameCode->Game.Code.toString}`,
      ]->UI.MultilineText.make,
    )
    Promise.resolve(None)
  }
}

module GameStatusWaitingForOpponentMoveRenderer = {
  let make = (~yourMove: Game.Move.t) => {
    UI.message(
      [
        "Waiting for your opponent's move...",
        `Your move: ${yourMove->moveToText}`,
      ]->UI.MultilineText.make,
    )
    Promise.resolve(None)
  }
}

module GameStatusReadyToPlayRenderer = {
  let make = () => {
    open UI.List
    prompt(
      ~message="What's your move?",
      ~choices=Game.Move.values->Array.map(move =>
        Choice.make(~name=move->moveToText, ~value=move)
      ),
    )->Promise.thenResolve(answer => {
      Some(AppService.GameEvent(AppService.GameMachine.SendMove(answer)))
    })
  }
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
  | Game({gameState: Status(WaitingForOpponentJoin), gameCode}) =>
    GameStatusWaitingForOpponentJoinRenderer.make(~gameCode)
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
    ~createGame=Api.CreateGame.make(),
    ~joinGame=Api.JoinGame.make(),
    ~requestGameStatus=Api.RequestGameStatus.make(),
    ~sendMove=Api.SendMove.make(),
  )
  let render = state' =>
    renderer(state')
    ->Promise.thenResolve(answer => {
      answer->Option.map(service->FSM.send)
    })
    ->ignore
  let _ = service->FSM.subscribe(state => {
    render(state)
  })

  service->FSM.start
  render(service->FSM.getCurrentState)
}

run()
