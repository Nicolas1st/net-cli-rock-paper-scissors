let apiCall = (
  ~path,
  ~method,
  ~body: option<'body>=?,
  ~bodyStruct: S.t<'body>,
  ~dataStruct: S.t<'data>,
): Promise.t<'data> => {
  let options: Undici.Request.options = {
    method: method,
    body: body
    ->S.serializeWith(bodyStruct->S.json->Obj.magic)
    ->ResultX.getExnWithMessage
    ->Obj.magic,
  }
  Undici.Request.call(~url=`${Env.apiHost}${path}`, ~options)
  ->Promise.then(response => {
    let contentLength =
      response.headers
      ->Js.Dict.get("content-length")
      ->Belt.Option.flatMap(Belt.Int.fromString)
      ->Belt.Option.getWithDefault(0)
    if contentLength === 0 {
      Promise.resolve(%raw(`undefined`))
    } else {
      response.body->Undici.Response.Body.json
    }
  })
  ->Promise.thenResolve(unknown => {
    unknown->S.parseWith(dataStruct)->ResultX.getExnWithMessage
  })
}

module Struct = {
  let nickname = S.string()->S.transform(
    ~parser=string =>
      switch string->Nickname.fromString {
      | Some(nickname) => Ok(nickname)
      | None => Error(`Invalid nickname. (${string})`)
      },
    ~serializer=value => value->Nickname.toString->Ok,
    (),
  )

  module Game = {
    let code = S.int()->S.transform(
      ~parser=int =>
        switch int->Js.Int.toString->Game.Code.fromString {
        | Some(gameCode) => Ok(gameCode)
        | None => Error(`Invalid game code. (${int->Obj.magic})`)
        },
      ~serializer=value => value->Game.Code.toString->Belt.Int.fromString->Belt.Option.getExn->Ok,
      (),
    )

    let move = S.union([
      S.literalVariant(String("rock"), Game.Move.Rock),
      S.literalVariant(String("paper"), Game.Move.Paper),
      S.literalVariant(String("scissors"), Game.Move.Scissors),
    ])

    let outcome = S.union([
      S.literalVariant(String("win"), Game.Win),
      S.literalVariant(String("draw"), Game.Draw),
      S.literalVariant(String("loss"), Game.Loss),
    ])
  }
}

module CreateGame = {
  let bodyStruct = S.record1(. ("userName", Struct.nickname))

  let dataStruct =
    S.record1(. ("gameCode", Struct.Game.code))->S.transform(
      ~parser=gameCode => {AppService.CreateGamePort.gameCode: gameCode}->Ok,
      (),
    )

  let call: AppService.CreateGamePort.t = (~nickname) => {
    apiCall(~path="/game", ~method=#POST, ~bodyStruct, ~dataStruct, ~body=nickname)
  }
}

module JoinGame = {
  let bodyStruct = S.record2(. ("userName", Struct.nickname), ("gameCode", Struct.Game.code))

  let dataStruct = S.literalUnit(EmptyOption)

  let call: AppService.JoinGamePort.t = (~nickname, ~gameCode) => {
    apiCall(
      ~path="/game/connection",
      ~method=#POST,
      ~bodyStruct,
      ~dataStruct,
      ~body=(nickname, gameCode),
    )
  }
}

module RequestGameStatus = {
  let dataStruct = {
    let waitingStruct =
      S.record1(. ("status", S.literalUnit(String("waiting"))))->S.transform(
        ~parser=() => AppService.RequestGameStatusPort.WaitingForOpponentJoin->Ok,
        (),
      )
    let inProcessStruct =
      S.record1(. ("status", S.literalUnit(String("inProcess"))))->S.transform(
        ~parser=() => AppService.RequestGameStatusPort.InProgress->Ok,
        (),
      )
    let finishedStruct =
      S.record2(.
        ("status", S.literalUnit(String("finished"))),
        (
          "gameResult",
          S.record3(.
            ("outcome", Struct.Game.outcome),
            ("yourMove", Struct.Game.move),
            ("opponentsMove", Struct.Game.move),
          ),
        ),
      )->S.transform(~parser=(((), (outcome, yourMove, opponentsMove))) =>
        AppService.RequestGameStatusPort.Finished({
          outcome: outcome,
          yourMove: yourMove,
          opponentsMove: opponentsMove,
        })->Ok
      , ())
    S.union([waitingStruct, inProcessStruct, finishedStruct])
  }

  let bodyStruct = S.record2(. ("userName", Struct.nickname), ("gameCode", Struct.Game.code))

  let call: AppService.RequestGameStatusPort.t = (~nickname, ~gameCode) => {
    apiCall(
      ~path="/game/status",
      ~method=#POST,
      ~bodyStruct,
      ~dataStruct,
      ~body=(nickname, gameCode),
    )
  }
}

module SendMove = {
  let bodyStruct = S.record3(.
    ("userName", Struct.nickname),
    ("gameCode", Struct.Game.code),
    ("move", Struct.Game.move),
  )

  let dataStruct = S.literalUnit(EmptyOption)

  let call: AppService.SendMovePort.t = (~nickname, ~gameCode, ~move) => {
    apiCall(
      ~path="/game/move",
      ~method=#POST,
      ~bodyStruct,
      ~dataStruct,
      ~body=(nickname, gameCode, move),
    )
  }
}
