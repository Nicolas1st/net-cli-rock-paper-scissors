type state = Menu | CreatingGame({userName: string}) | Game({gameCode: string}) | ErrorScreen
type event =
  CreateGame({userName: string}) | OnCreateGameSuccess({gameCode: string}) | OnCreateGameFailure

let machine = FSM.make(~reducer=(~state, ~event) => {
  switch (state, event) {
  | (Menu, CreateGame({userName})) => CreatingGame({userName: userName})
  | (CreatingGame(_), OnCreateGameSuccess({gameCode})) => Game({gameCode: gameCode})
  | (CreatingGame(_), OnCreateGameFailure) => ErrorScreen
  | (_, _) => state
  }
}, ~initialState=Menu)

let make = (~requestCreateGame) => {
  let service = machine->FSM.interpret
  service->FSM.subscribe(state => {
    switch state {
    | CreatingGame({userName}) =>
      requestCreateGame(~userName)
      ->Promise.thenResolve(result => {
        switch result {
        | Ok({Api.CreateGame.gameCode: gameCode}) =>
          service->FSM.send(OnCreateGameSuccess({gameCode: gameCode}))
        | Error() => service->FSM.send(OnCreateGameFailure)
        }
      })
      ->ignore
    | _ => ()
    }
  }, ())
  service
}
