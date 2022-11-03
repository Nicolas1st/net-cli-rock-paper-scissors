open Ava

let defaultGameCode = Game.Code.fromString("1234")->Option.getExn
let defaultNickname = Nickname.fromString("Dmitry")->Option.getExn

asyncTest("Successfully create game and start waiting for player", t => {
  t->Ava.ExecutionContext.plan(9)

  let stepNumberRef = ref(1)

  Promise.make((resolve, _) => {
    let service = AppService.make(
      ~createGame=(~nickname) => {
        t->Assert.deepEqual(nickname, defaultNickname, ())
        Promise.resolve({AppService.CreateGamePort.gameCode: defaultGameCode})
      },
      ~joinGame=(~nickname as _, ~gameCode as _) => {
        t->Assert.fail("Test CreateGameFlow")
      },
      ~requestGameStatus=(~nickname, ~gameCode) => {
        t->Assert.deepEqual(nickname, defaultNickname, ())
        t->Assert.deepEqual(gameCode, gameCode, ())
        Promise.resolve(AppService.RequestGameStatusPort.WaitingForOpponentJoin)
      },
      ~sendMove=(~nickname as _, ~gameCode as _, ~move as _) => {
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
  t->Ava.ExecutionContext.plan(17)

  let stepNumberRef = ref(1)

  Promise.make((resolve, _) => {
    let service = AppService.make(
      ~createGame=(~nickname as _) => {
        t->Assert.fail("Test JoinGameFlow")
      },
      ~joinGame=(~nickname, ~gameCode) => {
        t->Assert.deepEqual(nickname, defaultNickname, ())
        t->Assert.deepEqual(gameCode, defaultGameCode, ())
        Promise.resolve()
      },
      ~requestGameStatus=(~nickname, ~gameCode) => {
        t->Assert.deepEqual(nickname, defaultNickname, ())
        t->Assert.deepEqual(gameCode, defaultGameCode, ())
        Promise.resolve(AppService.RequestGameStatusPort.InProgress)
      },
      ~sendMove=(~nickname, ~gameCode, ~move) => {
        t->Assert.deepEqual(nickname, defaultNickname, ())
        t->Assert.deepEqual(gameCode, defaultGameCode, ())
        t->Assert.deepEqual(move, Rock, ())
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
