let apiCall = (
  ~path,
  ~method,
  ~body: 'body,
  ~bodyStruct: S.t<'body>,
  ~dataStruct: S.t<'data>,
): Promise.t<'data> => {
  let options: Undici.Request.options = {
    method,
    body: body->S.serializeWith(bodyStruct->S.json->Obj.magic)->S.Result.getExn->Obj.magic,
  }
  Undici.Request.call(~url=`${Env.apiUrl}${path}`, ~options)
  ->Promise.then(response => {
    let contentLength =
      response.headers
      ->Dict.get("content-length")
      ->Option.flatMap(Int.fromString)
      ->Option.getWithDefault(0)
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
        switch int->Int.toString->Game.Code.fromString {
        | Some(gameCode) => gameCode
        | None => S.Error.raise(`Invalid game code. (${int->Obj.magic})`)
        },
      ~serializer=value => value->Game.Code.toString->Int.fromString->Option.getExn,
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
  let bodyStruct = S.object(o => {"nickname": o->S.field("userName", Struct.nickname)})

  let dataStruct = S.object((o): AppService.CreateGamePort.data => {
    gameCode: o->S.field("gameCode", Struct.Game.code),
  })

  let call: AppService.CreateGamePort.t = (~nickname) => {
    apiCall(~path="/game", ~method=#POST, ~bodyStruct, ~dataStruct, ~body={"nickname": nickname})
  }
}

module JoinGame = {
  let bodyStruct = S.object(o =>
    {
      "nickname": o->S.field("userName", Struct.nickname),
      "gameCode": o->S.field("gameCode", Struct.Game.code),
    }
  )

  let dataStruct = S.literal(EmptyOption)

  let call: AppService.JoinGamePort.t = (~nickname, ~gameCode) => {
    apiCall(
      ~path="/game/connection",
      ~method=#POST,
      ~bodyStruct,
      ~dataStruct,
      ~body={
        "gameCode": gameCode,
        "nickname": nickname,
      },
    )
  }
}

module RequestGameStatus = {
  let bodyStruct = S.object(o =>
    {
      "nickname": o->S.field("userName", Struct.nickname),
      "gameCode": o->S.field("gameCode", Struct.Game.code),
    }
  )

  let dataStruct = S.union([
    S.object(o => {
      o->S.discriminant("status", S.literal(String("waiting")))
      AppService.RequestGameStatusPort.WaitingForOpponentJoin
    }),
    S.object(o => {
      o->S.discriminant("status", S.literal(String("inProcess")))
      AppService.RequestGameStatusPort.InProgress
    }),
    S.object(o => {
      o->S.discriminant("status", S.literal(String("finished")))
      o->S.field(
        "gameResult",
        S.object(o => AppService.RequestGameStatusPort.Finished({
          outcome: o->S.field("outcome", Struct.Game.outcome),
          yourMove: o->S.field("yourMove", Struct.Game.move),
          opponentsMove: o->S.field("opponentsMove", Struct.Game.move),
        })),
      )
    }),
  ])

  let call: AppService.RequestGameStatusPort.t = (~nickname, ~gameCode) => {
    apiCall(
      ~path="/game/status",
      ~method=#POST,
      ~bodyStruct,
      ~dataStruct,
      ~body={
        "gameCode": gameCode,
        "nickname": nickname,
      },
    )
  }
}

module SendMove = {
  let bodyStruct = S.object(o =>
    {
      "nickname": o->S.field("userName", Struct.nickname),
      "gameCode": o->S.field("gameCode", Struct.Game.code),
      "move": o->S.field("move", Struct.Game.move),
    }
  )

  let dataStruct = S.literal(EmptyOption)

  let call: AppService.SendMovePort.t = (~nickname, ~gameCode, ~move) => {
    apiCall(
      ~path="/game/move",
      ~method=#POST,
      ~bodyStruct,
      ~dataStruct,
      ~body={
        "gameCode": gameCode,
        "nickname": nickname,
        "move": move,
      },
    )
  }
}
