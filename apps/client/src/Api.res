let host = "http://localhost:8880"

let unwrapResult = result => {
  switch result {
  | Ok(value) => value
  | Error(message) => Js.Exn.raiseError(message)
  }
}

let unitStruct: S.t<unit> =
  S.unknown()->S.transformUnknown(~constructor=unknown => Obj.magic(unknown)->Ok, ())

let gameCodeStruct =
  S.int()->S.transform(
    ~constructor=int => int->Js.Int.toString->Ok,
    ~destructor=value => value->Belt.Int.fromString->Belt.Option.getExn->Ok,
    (),
  )

let apiCall = (
  ~path,
  ~method,
  ~body: option<'body>=?,
  ~bodyStruct: S.t<'body>,
  ~dataStruct: S.t<'data>,
): Promise.t<'data> => {
  let options: Undici.Request.options = {
    method: method,
    body: body->S.serializeWith(bodyStruct->S.json->Obj.magic)->unwrapResult->Obj.magic,
  }
  Undici.Request.call(~url=`${host}${path}`, ~options, ())
  ->Promise.then(response => {
    if response.statusCode === 204 {
      Promise.resolve(%raw(`undefined`))
    } else {
      response.body.json(.)
    }
  })
  ->Promise.thenResolve(unknown => {
    unknown->S.parseWith(dataStruct)->unwrapResult
  })
}

let moveStruct = S.string()->S.transform(
  ~constructor=data => {
    switch data {
    | "rock" => Game.Move.Rock->Ok
    | "paper" => Paper->Ok
    | "scissors" => Scissors->Ok
    | unknownData => Error(`The provided move "${unknownData}" is unknown`)
    }
  },
  ~destructor=value => {
    switch value {
    | Rock => "rock"
    | Paper => "paper"
    | Scissors => "scissors"
    }->Ok
  },
  (),
)

module CreateGame = {
  type body = {userName: string}
  let bodyStruct = S.record1(
    ~fields=("userName", S.string()),
    ~destructor=({userName}) => userName->Ok,
    (),
  )
  let dataStruct = S.record1(
    ~fields=("gameCode", gameCodeStruct),
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
    ~fields=(("userName", S.string()), ("gameCode", gameCodeStruct)),
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
    ~fields=(("userName", S.string()), ("gameCode", gameCodeStruct)),
    ~destructor=({userName, gameCode}) => (userName, gameCode)->Ok,
    (),
  )
  type backendStatusType = [#waiting | #inProcess | #finished]
  let backendStatusStruct =
    S.record1(~fields=("status", S.string()->S.transform(~constructor=value => {
          switch Obj.magic(value) {
          | #...backendStatusType as backendStatusType => backendStatusType->Ok
          | unknownValue =>
            Error(`The provided status type "${unknownValue->Obj.magic}" is unknown`)
          }
        }, ())), ~constructor=backendStatusType => backendStatusType->Ok, ())->S.Record.strip
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
  let gameResultStruct = S.record2(
    ~fields=(("status", S.unknown()), ("gameResult", finishedContextStruct)),
    ~constructor=((_, finishedContext)) => finishedContext->Ok,
    (),
  )
  let dataStruct = S.unknown()->S.transformUnknown(~constructor=unknown =>
    unknown
    ->S.parseWith(backendStatusStruct)
    ->Belt.Result.flatMap(backendStatusType => {
      switch backendStatusType {
      | #waiting => AppService.RequestGameStatusPort.WaitingForOpponentJoin->Ok
      | #inProcess => AppService.RequestGameStatusPort.InProgress->Ok
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
      ~path="/game/status",
      ~method=#POST,
      ~bodyStruct,
      ~dataStruct,
      ~body={userName: userName, gameCode: gameCode},
    )
  }
}

module SendMove = {
  type body = {userName: string, gameCode: string, move: Game.Move.t}
  let bodyStruct = S.record3(
    ~fields=(("userName", S.string()), ("gameCode", gameCodeStruct), ("move", moveStruct)),
    ~destructor=({userName, gameCode, move}) => (userName, gameCode, move)->Ok,
    (),
  )
  let call: AppService.SendMovePort.t = (~userName, ~gameCode, ~move) => {
    apiCall(
      ~path="/game/move",
      ~method=#POST,
      ~bodyStruct,
      ~dataStruct=unitStruct,
      ~body={userName: userName, gameCode: gameCode, move: move},
    )
  }
}
