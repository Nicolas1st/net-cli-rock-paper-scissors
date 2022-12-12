open Ava

let defaultGameCode = Game.Code.fromString("1234")->Option.getExnWithMessage("Invalid game code.")
let defaultNickname = Nickname.fromString("Dmitry")->Option.getExnWithMessage("Invalid nickname.")

asyncTest("Successfully create game and start waiting for player", t => {
  t->Ava.ExecutionContext.plan(8)

  let stepNumberRef = ref(1)

  Promise.make((resolve, _) => {
    let service = AppService.make(
      ~createGame=(. input) => {
        t->Assert.deepEqual(input, {nickname: defaultNickname}, ())
        Promise.resolve({Port.CreateGame.gameCode: defaultGameCode})
      },
      ~joinGame=(. _) => {
        t->Assert.fail("Test CreateGameFlow")
      },
      ~requestGameStatus=(. input) => {
        t->Assert.deepEqual(input, {nickname: defaultNickname, gameCode: defaultGameCode}, ())
        Promise.resolve(Port.RequestGameStatus.WaitingForOpponentJoin)
      },
      ~sendMove=(. _) => {
        t->Assert.fail("Test CreateGameFlow")
      },
    )

    let _ = service->FSM.subscribe(
      state => {
        stepNumberRef.contents = stepNumberRef.contents + 1
        switch state {
        | CreatingGame(_) => {
            t->Assert.deepEqual(state, AppService.CreatingGame({nickname: defaultNickname}), ())
            t->Assert.is(stepNumberRef.contents, 2, ())
          }

        | Game({gameState: Loading}) => t->Assert.is(stepNumberRef.contents, 3, ())
        | Game({gameState: Status(WaitingForOpponentJoin)}) => {
            t->Assert.is(stepNumberRef.contents, 4, ())

            service->FSM.send(AppService.Exit)
          }

        | Exiting => {
            t->Assert.is(stepNumberRef.contents, 5, ())

            resolve(. Obj.magic(""))
          }

        | _ => ()
        }
      },
    )

    t->Assert.deepEqual(service->FSM.getCurrentState, AppService.Menu, ())

    service->FSM.start
    service->FSM.send(AppService.CreateGame({nickname: defaultNickname}))
  })
})

asyncTest("Successfully join game and start playing", t => {
  t->Ava.ExecutionContext.plan(13)

  let stepNumberRef = ref(1)

  Promise.make((resolve, _) => {
    let service = AppService.make(
      ~createGame=(. _) => {
        t->Assert.fail("Test JoinGameFlow")
      },
      ~joinGame=(. input) => {
        t->Assert.deepEqual(input, {nickname: defaultNickname, gameCode: defaultGameCode}, ())
        Promise.resolve()
      },
      ~requestGameStatus=(. input) => {
        t->Assert.deepEqual(input, {nickname: defaultNickname, gameCode: defaultGameCode}, ())
        Promise.resolve(Port.RequestGameStatus.InProgress)
      },
      ~sendMove=(. input) => {
        t->Assert.deepEqual(
          input,
          {nickname: defaultNickname, gameCode: defaultGameCode, yourMove: Rock},
          (),
        )
        Promise.resolve()
      },
    )

    let _ = service->FSM.subscribe(
      state => {
        stepNumberRef.contents = stepNumberRef.contents + 1
        switch state {
        | CreatingGame(_) => {
            t->Assert.deepEqual(state, AppService.CreatingGame({nickname: defaultNickname}), ())
            t->Assert.is(stepNumberRef.contents, 2, ())
          }

        | Game({gameState: Loading}) => t->Assert.is(stepNumberRef.contents, 3, ())
        | Game({gameState: Status(ReadyToPlay)}) => {
            t->Assert.is(stepNumberRef.contents, 4, ())

            service->FSM.send(AppService.GameEvent(SendMove(Rock)))
          }

        | Game({gameState: Status(WaitingForOpponentMove({yourMove}))}) => {
            t->Assert.deepEqual(yourMove, Rock, ())
            t->Assert.is(stepNumberRef.contents, 5, ())

            service->FSM.send(
              AppService.GameEvent(
                OnGameStatus(
                  Finished({
                    yourMove: Rock,
                    opponentsMove: Scissors,
                    outcome: Win,
                  }),
                ),
              ),
            )
          }

        | Game({gameState: Status(Finished({yourMove, opponentsMove, outcome}))}) => {
            t->Assert.deepEqual(yourMove, Rock, ())
            t->Assert.deepEqual(opponentsMove, Scissors, ())
            t->Assert.deepEqual(outcome, Win, ())
            t->Assert.is(stepNumberRef.contents, 6, ())

            service->FSM.send(AppService.Exit)
          }

        | Exiting => {
            t->Assert.is(stepNumberRef.contents, 7, ())

            resolve(. Obj.magic(""))
          }

        | _ => ()
        }
      },
    )

    t->Assert.deepEqual(service->FSM.getCurrentState, AppService.Menu, ())

    service->FSM.start
    service->FSM.send(AppService.JoinGame({nickname: defaultNickname, gameCode: defaultGameCode}))
  })
})
