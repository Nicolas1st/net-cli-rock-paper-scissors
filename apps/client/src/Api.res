let host = "http://localhost:8880"

module CreateGame = {
  type body = {userName: string}
  let bodyStruct = S.record1(
    ~fields=("userName", S.string()),
    ~destructor=({userName}) => userName->Ok,
    (),
  )
  let dataStruct = S.record1(
    ~fields=("gameCode", S.string()),
    ~constructor=gameCode => {AppService.CreateGamePort.gameCode: gameCode}->Ok,
    (),
  )
  let call: AppService.CreateGamePort.t = (~userName) => {
    Undici.Request.call(
      ~url=`${host}/game`,
      ~options={
        method: #POST,
        body: {userName: userName}
        ->S.serializeWith(bodyStruct->S.json)
        ->Belt.Result.getExn
        ->Obj.magic,
      },
      (),
    )
    ->Promise.then(response => response.body.json())
    ->Promise.thenResolve(unknown => {
      switch unknown->S.parseWith(dataStruct) {
      | Ok(_) as ok => ok
      | Error(message) => Js.Exn.raiseError(message)
      }
    })
  }
}

module JoinGame = {
  type body = {userName: string, gameCode: string}
  let bodyStruct = S.record2(
    ~fields=(("userName", S.string()), ("gameCode", S.string())),
    ~destructor=({userName, gameCode}) => (userName, gameCode)->Ok,
    (),
  )
  let call: AppService.JoinGamePort.t = (~userName, ~gameCode) => {
    Undici.Request.call(
      ~url=`${host}/game/connection`,
      ~options={
        method: #POST,
        body: {userName: userName, gameCode: gameCode}
        ->S.serializeWith(bodyStruct->S.json)
        ->Belt.Result.getExn
        ->Obj.magic,
      },
      (),
    )
    ->Promise.then(response => response.body.json())
    ->Promise.thenResolve(_ => {
      Ok()
    })
  }
}

module RequestGameStatus = {
  type body = {userName: string, gameCode: string}
  let bodyStruct = S.record2(
    ~fields=(("userName", S.string()), ("gameCode", S.string())),
    ~destructor=({userName, gameCode}) => (userName, gameCode)->Ok,
    (),
  )
  let call: AppService.RequestGameStatusPort.t = (~userName, ~gameCode) => {
    Undici.Request.call(
      ~url=`${host}/status`,
      ~options={
        method: #GET,
        body: {userName: userName, gameCode: gameCode}
        ->S.serializeWith(bodyStruct->S.json)
        ->Belt.Result.getExn
        ->Obj.magic,
      },
      (),
    )
    ->Promise.then(response => response.body.json())
    ->Promise.thenResolve(_ => {
      Ok(Game.WaitingForPlayer)
    })
  }
}
