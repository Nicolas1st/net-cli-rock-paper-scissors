module Port = {
  module RequestJoinGame = {
    type t = (~userName: string, ~gameCode: string) => Promise.t<result<unit, unit>>
  }

  module RequestCreateGame = {
    type data = {gameCode: string}
    type t = (~userName: string) => Promise.t<result<data, unit>>
  }
}

type state =
  | Menu
  | CreatingGame({userName: string})
  | JoiningGame({userName: string, gameCode: string})
  | Game({gameCode: string, userName: string})
type event =
  | CreateGame({userName: string})
  | OnCreateGameSuccess({gameCode: string})
  | OnCreateGameFailure
  | JoinGame({userName: string, gameCode: string})
  | OnJoinGameSuccess
  | OnJoinGameFailure

let machine = FSM.make(~reducer=(~state, ~event) => {
  switch (state, event) {
  | (Menu, CreateGame({userName})) => CreatingGame({userName: userName})
  | (CreatingGame({userName}), OnCreateGameSuccess({gameCode})) =>
    Game({gameCode: gameCode, userName: userName})
  | (CreatingGame(_), OnCreateGameFailure) => Menu
  | (Menu, JoinGame({userName, gameCode})) => JoiningGame({userName: userName, gameCode: gameCode})
  | (JoiningGame({userName, gameCode}), OnJoinGameSuccess) =>
    Game({gameCode: gameCode, userName: userName})
  | (JoiningGame(_), OnJoinGameFailure) => Menu
  | (_, _) => state
  }
}, ~initialState=Menu)

let make = (
  ~requestCreateGame: Port.RequestCreateGame.t,
  ~requestJoinGame: Port.RequestJoinGame.t,
) => {
  let service = machine->FSM.interpret
  let _ = service->FSM.subscribe(state => {
    switch state {
    | CreatingGame({userName}) =>
      requestCreateGame(~userName)
      ->Promise.thenResolve(result => {
        switch result {
        | Ok({Port.RequestCreateGame.gameCode: gameCode}) =>
          service->FSM.send(OnCreateGameSuccess({gameCode: gameCode}))
        | Error() => service->FSM.send(OnCreateGameFailure)
        }
      })
      ->ignore
    | JoiningGame({userName, gameCode}) =>
      requestJoinGame(~userName, ~gameCode)
      ->Promise.thenResolve(result => {
        switch result {
        | Ok() => service->FSM.send(OnJoinGameSuccess)
        | Error() => service->FSM.send(OnJoinGameFailure)
        }
      })
      ->ignore
    | _ => ()
    }
  })
  service
}
