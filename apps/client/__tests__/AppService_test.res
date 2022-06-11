open Ava

asyncTest("Works", t => {
  t->Ava.ExecutionContext.plan(7)

  let stepNumberRef = ref(1)

  Promise.make((resolve, _) => {
    let service = AppService.make(
      ~createGame=(~userName) => {
        t->Assert.deepEqual(userName, "Dmitry", ())
        Promise.resolve(Ok({AppService.CreateGamePort.gameCode: "1234"}))
      },
      ~joinGame=(~userName as _, ~gameCode as _) => {
        t->Assert.fail("Test CreateGameFlow")
      },
      ~requestGameStatus=(~userName, ~gameCode) => {
        t->Assert.deepEqual(userName, "Dmitry", ())
        t->Assert.deepEqual(gameCode, "1234", ())
        Promise.resolve(Ok())
      },
    )

    let _ = service->FSM.subscribe(state => {
      stepNumberRef.contents = stepNumberRef.contents + 1
      switch state {
      | CreatingGame(_) => {
          t->Assert.deepEqual(state, AppService.CreatingGame({userName: "Dmitry"}), ())
          t->Assert.is(stepNumberRef.contents, 2, ())
        }
      | Game({gameState: Loading}) => {
          t->Assert.is(stepNumberRef.contents, 3, ())
          resolve(. Obj.magic(""))
        }
      | _ => ()
      }
    })

    t->Assert.deepEqual(service->FSM.getCurrentState, AppService.Menu, ())

    service->FSM.send(AppService.CreateGame({userName: "Dmitry"}))
  })
})
