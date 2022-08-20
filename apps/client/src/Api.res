let apiCall = (
  ~path,
  ~method,
  ~body: option<'body>=?,
  ~bodyStruct: S.t<'body>,
  ~dataStruct: S.t<'data>,
): Promise.t<'data> => {
  let options: Undici.Request.options = {
    method: method,
    body: body->S.serializeWith(bodyStruct->S.json->Obj.magic)->S.Result.getExn->Obj.magic,
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
    unknown->S.parseWith(dataStruct)->S.Result.getExn
  })
}

module Struct = {
  let nickname = S.string()->S.transform(~parser=string =>
    switch string->Nickname.fromString {
    | Some(nickname) => nickname
    | None => S.Error.raise(`Invalid nickname. (${string})`)
    }
  , ~serializer=Nickname.toString, ())

  module Game = {
    let code = S.int()->S.transform(
      ~parser=int =>
        switch int->Js.Int.toString->Game.Code.fromString {
        | Some(gameCode) => gameCode
        | None => S.Error.raise(`Invalid game code. (${int->Obj.magic})`)
        },
      ~serializer=value => value->Game.Code.toString->Belt.Int.fromString->Belt.Option.getExn,
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
      ~parser=gameCode => {AppService.CreateGamePort.gameCode: gameCode},
      (),
    )

  let call: AppService.CreateGamePort.t = (~nickname) => {
    apiCall(~path="/game", ~method=#POST, ~bodyStruct, ~dataStruct, ~body=nickname)
  }
}

module JoinGame = {
  let bodyStruct = S.record2(. ("userName", Struct.nickname), ("gameCode", Struct.Game.code))

  let dataStruct = S.literal(EmptyOption)

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
    let waitingStruct = S.record1(. (
      "status",
      S.literalVariant(String("waiting"), AppService.RequestGameStatusPort.WaitingForOpponentJoin),
    ))
    let inProcessStruct = S.record1(. (
      "status",
      S.literalVariant(String("inProcess"), AppService.RequestGameStatusPort.InProgress),
    ))
    let finishedStruct =
      S.record2(.
        ("status", S.literalVariant(String("finished"), ())),
        (
          "gameResult",
          S.record3(.
            ("outcome", Struct.Game.outcome),
            ("yourMove", Struct.Game.move),
            ("opponentsMove", Struct.Game.move),
          ),
        ),
      )->S.transform(
        ~parser=((
          (),
          (outcome, yourMove, opponentsMove),
        )) => AppService.RequestGameStatusPort.Finished({
          outcome: outcome,
          yourMove: yourMove,
          opponentsMove: opponentsMove,
        }),
        (),
      )
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

  let dataStruct = S.literal(EmptyOption)

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
