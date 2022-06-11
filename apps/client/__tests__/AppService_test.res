open Ava

asyncTest("Works", t => {
  t->Ava.ExecutionContext.plan(3)

  Promise.make((resolve, _) => {
    let service = AppService.make(
      ~createGame=(~userName) => {
        t->Assert.deepEqual(userName, "Dmitry", ())
        Promise.resolve(Ok({AppService.Port.CreateGame.gameCode: "1234"}))
      },
      ~joinGame=(~userName as _, ~gameCode as _) => {
        t->Assert.fail("Test CreateGameFlow")
      },
    )

    let _ = service->FSM.subscribe(state => {
      switch state {
      | CreatingGame(_) => resolve(. Obj.magic(""))
      | _ => ()
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
