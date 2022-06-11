open Ava

asyncTest("Works", t => {
  t->Ava.ExecutionContext.plan(3)

  Promise.make((resolve, _) => {
    let service = AppService.make(
      ~requestCreateGame=(~userName) => {
        t->Assert.deepEqual(userName, "Dmitry", ())
        Promise.resolve(Ok({AppService.Port.RequestCreateGame.gameCode: "1234"}))
      },
      ~requestJoinGame=(~userName as _, ~gameCode as _) => {
        t->Assert.fail("Test CreateGameFlow")
      },
    )

    let _ = service->FSM.subscribe(state => {
      // Test exit condition
      if state == AppService.CreatingGame({userName: "Dmitry"}) {
        resolve(. Obj.magic(""))
      }
    })

    t->Assert.deepEqual(service->FSM.getCurrentState, AppService.Menu, ())

    service->FSM.send(AppService.CreateGame({userName: "Dmitry"}))

    t->Assert.deepEqual(
      service->FSM.getCurrentState,
      AppService.CreatingGame({userName: "Dmitry"}),
      (),
    )
  })
})
