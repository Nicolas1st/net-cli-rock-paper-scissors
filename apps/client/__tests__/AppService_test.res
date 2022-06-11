open Ava

test("Works", t => {
  let service = AppService.make(~requestCreateGame=Api.CreateGame.call)

  t->Assert.deepEqual(service->FSM.getCurrentState, AppService.Menu, ())

  service->FSM.send(AppService.CreateGame({userName: "Dmitry"}))

  t->Assert.deepEqual(
    service->FSM.getCurrentState,
    AppService.CreatingGame({userName: "Dmitry"}),
    (),
  )
})
