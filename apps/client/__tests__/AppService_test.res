open Ava

asyncTest("Successfully create game and start waiting for player", t => {
  t->Ava.ExecutionContext.plan(8)

  let stepNumberRef = ref(1)

  Promise.make((resolve, _) => {
    let service = AppService.make(
      ~createGame=(~userName) => {
        t->Assert.deepEqual(userName, "Dmitry", ())
        Promise.resolve({AppService.CreateGamePort.gameCode: "1234"})
      },
      ~joinGame=(~userName as _, ~gameCode as _) => {
        t->Assert.fail("Test CreateGameFlow")
      },
      ~requestGameStatus=(~userName, ~gameCode) => {
        t->Assert.deepEqual(userName, "Dmitry", ())
        t->Assert.deepEqual(gameCode, "1234", ())
        Promise.resolve(AppService.RequestGameStatusPort.WaitingForOpponentJoin)
      },
      ~sendMove=(~userName as _, ~gameCode as _, ~move as _) => {
        t->Assert.fail("Test CreateGameFlow")
      },
    )

    let _ = service->FSM.subscribe(state => {
      stepNumberRef.contents = stepNumberRef.contents + 1
      switch state {
      | CreatingGame(_) => {
          t->Assert.deepEqual(state, AppService.CreatingGame({userName: "Dmitry"}), ())
          t->Assert.is(stepNumberRef.contents, 2, ())
        }
      | Game({gameState: Loading}) => t->Assert.is(stepNumberRef.contents, 3, ())
      | Game({gameState: Status(WaitingForOpponentJoin)}) => {
          t->Assert.is(stepNumberRef.contents, 4, ())
          resolve(. Obj.magic(""))
        }
      | _ => ()
      }
    })

    t->Assert.deepEqual(service->FSM.getCurrentState, AppService.Menu, ())

    service->FSM.send(AppService.CreateGame({userName: "Dmitry"}))
  })
})

asyncTest("Successfully join game and start playing", t => {
  t->Ava.ExecutionContext.plan(16)

  let stepNumberRef = ref(1)

  Promise.make((resolve, _) => {
    let service = AppService.make(
      ~createGame=(~userName as _) => {
        t->Assert.fail("Test JoinGameFlow")
      },
      ~joinGame=(~userName, ~gameCode) => {
        t->Assert.deepEqual(userName, "Dmitry", ())
        t->Assert.deepEqual(gameCode, "1234", ())
        Promise.resolve()
      },
      ~requestGameStatus=(~userName, ~gameCode) => {
        t->Assert.deepEqual(userName, "Dmitry", ())
        t->Assert.deepEqual(gameCode, "1234", ())
        Promise.resolve(AppService.RequestGameStatusPort.InProgress)
      },
      ~sendMove=(~userName, ~gameCode, ~move) => {
        t->Assert.deepEqual(userName, "Dmitry", ())
        t->Assert.deepEqual(gameCode, "1234", ())
        t->Assert.deepEqual(move, Rock, ())
        Promise.resolve()
      },
    )

    let _ = service->FSM.subscribe(state => {
      stepNumberRef.contents = stepNumberRef.contents + 1
      switch state {
      | CreatingGame(_) => {
          t->Assert.deepEqual(state, AppService.CreatingGame({userName: "Dmitry"}), ())
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

          resolve(. Obj.magic(""))
        }
      | _ => ()
      }
    })

    t->Assert.deepEqual(service->FSM.getCurrentState, AppService.Menu, ())

    service->FSM.send(AppService.JoinGame({userName: "Dmitry", gameCode: "1234"}))
  })
})
