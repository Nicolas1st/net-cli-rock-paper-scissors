let host = "http://localhost:8880"

let unitStruct: S.t<unit> =
  S.unknown()->S.transformUnknown(~constructor=unknown => Obj.magic(unknown)->Ok, ())

let apiCall = (
  ~path,
  ~method,
  ~body: option<'body>=?,
  ~bodyStruct: S.t<'body>,
  ~dataStruct: S.t<'data>,
): Promise.t<'data> => {
  Undici.Request.call(
    ~url=`${host}${path}`,
    ~options={
      method: method,
      body: body->S.serializeWith(bodyStruct->S.json->Obj.magic)->Belt.Result.getExn->Obj.magic,
    },
    (),
  )
  ->Promise.then(response => response.body.json())
  ->Promise.thenResolve(unknown => {
    unknown->S.parseWith(dataStruct)->Belt.Result.getExn
  })
}

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
    apiCall(~path="/game", ~method=#POST, ~bodyStruct, ~dataStruct, ~body={userName: userName})
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
    apiCall(
      ~path="/game/connection",
      ~method=#POST,
      ~bodyStruct,
      ~dataStruct=unitStruct,
      ~body={userName: userName, gameCode: gameCode},
    )
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
  let dataStruct = S.unknown()->S.transformUnknown(~constructor=unknown =>
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
    apiCall(
      ~path="/status",
      ~method=#GET,
      ~bodyStruct,
      ~dataStruct,
      ~body={userName: userName, gameCode: gameCode},
    )
  }
}
