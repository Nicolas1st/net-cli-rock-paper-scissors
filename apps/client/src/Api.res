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
  type backendStatusType = [#waitingForOpponent | #inProccess | #finished]
  let backendStatusStruct = S.record1(
    ~fields=("type", S.string()->S.transform(~constructor=value => {
        switch Obj.magic(value) {
        | #...backendStatusType as backendStatusType => backendStatusType->Ok
        | unknownValue => Error(`The provided status type "${unknownValue->Obj.magic}" is unknown`)
        }
      }, ())),
    ~constructor=backendStatusType => backendStatusType->Ok,
    (),
  )

  let moveStruct = S.string()->S.transform(~constructor=value => {
    switch value {
    | "rock" => Game.Rock->Ok
    | "paper" => Paper->Ok
    | "scissors" => Scissors->Ok
    | unknownValue => Error(`The provided move "${unknownValue}" is unknown`)
    }
  }, ())
  let outcomeStruct = S.string()->S.transform(~constructor=value => {
    switch value {
    | "win" => Game.Win->Ok
    | "draw" => Draw->Ok
    | "loss" => Loss->Ok
    | unknownValue => Error(`The provided outcome "${unknownValue}" is unknown`)
    }
  }, ())
  let finishedContextStruct = S.record3(
    ~fields=(("outcome", outcomeStruct), ("yourMove", moveStruct), ("opponentsMove", moveStruct)),
    ~constructor=((outcome, yourMove, opponentsMove)) =>
      {Game.outcome: outcome, yourMove: yourMove, opponentsMove: opponentsMove}->Ok,
    (),
  )
  let gameResultStruct = S.record1(
    ~fields=("gameResult", finishedContextStruct),
    ~constructor=finishedContext => finishedContext->Ok,
    (),
  )
  let statusStruct = S.unknown()->S.transformUnknown(~constructor=unknown =>
    unknown
    ->S.parseWith(backendStatusStruct)
    ->Belt.Result.flatMap(backendStatusType => {
      switch backendStatusType {
      | #waitingForOpponent => AppService.RequestGameStatusPort.WaitingForOpponentJoin->Ok
      | #inProccess => AppService.RequestGameStatusPort.InProgress->Ok
      | #finished =>
        unknown
        ->S.parseWith(gameResultStruct)
        ->Belt.Result.map(finishedContext => AppService.RequestGameStatusPort.Finished(
          finishedContext,
        ))
      }
    })
  , ())

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
    ->Promise.thenResolve(unknown => {
      switch unknown->S.parseWith(statusStruct) {
      | Ok(_) as ok => ok
      | Error(message) => Js.Exn.raiseError(message)
      }
    })
  }
}
