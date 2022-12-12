module Http = {
  let make = (~path, ~method, ~inputStruct: S.t<'input>, ~dataStruct: S.t<'data>) =>
    (. input: 'input): Promise.t<'data> => {
      let options: Undici.Request.options = {
        method,
        body: input
        ->S.serializeWith(inputStruct)
        ->S.Result.getExn
        ->Json.stringifyAny
        ->Option.getExnWithMessage(
          `Failed to serialize input to JSON for the "${(method :> string)}" request to "${path}".`,
        ),
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
      ~serializer=value =>
        switch value->Game.Code.toString->Int.fromString {
        | Some(int) => int
        | None => S.Error.raise(`Invalid game code.`)
        },
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
  let make = (): Port.CreateGame.t => {
    Http.make(
      ~path="/game",
      ~method=#POST,
      ~inputStruct=S.object((o): Port.CreateGame.input => {
        nickname: o->S.field("userName", Struct.nickname),
      }),
      ~dataStruct=S.object((o): Port.CreateGame.data => {
        gameCode: o->S.field("gameCode", Struct.Game.code),
      }),
    )
  }
}

module JoinGame = {
  let make = (): Port.JoinGame.t => {
    Http.make(
      ~path="/game/connection",
      ~method=#POST,
      ~inputStruct=S.object((o): Port.JoinGame.input => {
        nickname: o->S.field("userName", Struct.nickname),
        gameCode: o->S.field("gameCode", Struct.Game.code),
      }),
      ~dataStruct=S.literal(EmptyOption),
    )
  }
}

module RequestGameStatus = {
  let make = (): Port.RequestGameStatus.t => {
    Http.make(
      ~path="/game/status",
      ~method=#POST,
      ~inputStruct=S.object((o): Port.RequestGameStatus.input => {
        nickname: o->S.field("userName", Struct.nickname),
        gameCode: o->S.field("gameCode", Struct.Game.code),
      }),
      ~dataStruct=S.union([
        S.object(o => {
          o->S.discriminant("status", S.literal(String("waiting")))
          Port.RequestGameStatus.WaitingForOpponentJoin
        }),
        S.object(o => {
          o->S.discriminant("status", S.literal(String("inProcess")))
          Port.RequestGameStatus.InProgress
        }),
        S.object(o => {
          o->S.discriminant("status", S.literal(String("finished")))
          o->S.field(
            "gameResult",
            S.object(o => Port.RequestGameStatus.Finished({
              outcome: o->S.field("outcome", Struct.Game.outcome),
              yourMove: o->S.field("yourMove", Struct.Game.move),
              opponentsMove: o->S.field("opponentsMove", Struct.Game.move),
            })),
          )
        }),
      ]),
    )
  }
}

module SendMove = {
  let make = (): Port.SendMove.t => {
    Http.make(
      ~path="/game/move",
      ~method=#POST,
      ~inputStruct=S.object((o): Port.SendMove.input => {
        nickname: o->S.field("userName", Struct.nickname),
        gameCode: o->S.field("gameCode", Struct.Game.code),
        yourMove: o->S.field("move", Struct.Game.move),
      }),
      ~dataStruct=S.literal(EmptyOption),
    )
  }
}
