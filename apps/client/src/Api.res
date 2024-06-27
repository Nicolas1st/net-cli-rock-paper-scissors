module Http = {
  let make = (~path, ~method, ~inputSchema: S.t<'input>, ~dataSchema: S.t<'data>) => (
    input: 'input,
  ): Promise.t<'data> => {
    let options: Undici.Request.options = {
      method,
      body: switch input->S.serializeToJsonStringWith(inputSchema) {
      | Ok(jsonString) => jsonString
      | Error(error) => S.Error.raise(error)
      },
    }
    Undici.Request.call(~url=`${Env.apiUrl}${path}`, ~options)
    ->Promise.then(response => {
      let contentLength =
        response.headers
        ->Dict.get("content-length")
        ->Option.flatMap(Int.fromString(_))
        ->Option.getOr(0)
      if contentLength === 0 {
        Promise.resolve(%raw(`undefined`))
      } else {
        response.body->Undici.Response.Body.json
      }
    })
    ->Promise.thenResolve(unknown => {
      unknown->S.parseAnyOrRaiseWith(dataSchema)
    })
  }
}

module Schema = {
  let nickname = S.string->S.transform(s => {
    parser: string =>
      switch string->Nickname.fromString {
      | Some(nickname) => nickname
      | None => s.fail(`Invalid nickname. (${string})`)
      },
    serializer: Nickname.toString,
  })

  module Game = {
    let code = S.int->S.transform(s => {
      parser: int =>
        switch int->Int.toString->Game.Code.fromString {
        | Some(gameCode) => gameCode
        | None => s.fail(`Invalid game code. (${int->Obj.magic})`)
        },
      serializer: value =>
        switch value->Game.Code.toString->Int.fromString {
        | Some(int) => int
        | None => s.fail(`Invalid game code.`)
        },
    })

    let move = S.union([
      S.literal("rock")->S.variant(_ => Game.Move.Rock),
      S.literal("paper")->S.variant(_ => Game.Move.Paper),
      S.literal("scissors")->S.variant(_ => Game.Move.Scissors),
    ])

    let outcome = S.union([
      S.literal("win")->S.variant(_ => Game.Win),
      S.literal("draw")->S.variant(_ => Game.Draw),
      S.literal("loss")->S.variant(_ => Game.Loss),
    ])
  }
}

module CreateGame = {
  let make = (): Port.CreateGame.t => {
    Http.make(
      ~path="/game",
      ~method=#POST,
      ~inputSchema=S.object((s): Port.CreateGame.input => {
        nickname: s.field("userName", Schema.nickname),
      }),
      ~dataSchema=S.object((s): Port.CreateGame.data => {
        gameCode: s.field("gameCode", Schema.Game.code),
      }),
    )
  }
}

module JoinGame = {
  let make = (): Port.JoinGame.t => {
    Http.make(
      ~path="/game/connection",
      ~method=#POST,
      ~inputSchema=S.object((s): Port.JoinGame.input => {
        nickname: s.field("userName", Schema.nickname),
        gameCode: s.field("gameCode", Schema.Game.code),
      }),
      ~dataSchema=S.unit,
    )
  }
}

module RequestGameStatus = {
  let make = (): Port.RequestGameStatus.t => {
    Http.make(
      ~path="/game/status",
      ~method=#POST,
      ~inputSchema=S.object((s): Port.RequestGameStatus.input => {
        nickname: s.field("userName", Schema.nickname),
        gameCode: s.field("gameCode", Schema.Game.code),
      }),
      ~dataSchema=S.union([
        S.object(s => {
          s.tag("status", "waiting")
          Port.RequestGameStatus.WaitingForOpponentJoin
        }),
        S.object(s => {
          s.tag("status", "inProcess")
          Port.RequestGameStatus.InProgress
        }),
        S.object(s => {
          s.tag("status", "finished")
          s.field(
            "gameResult",
            S.object(s => Port.RequestGameStatus.Finished({
              outcome: s.field("outcome", Schema.Game.outcome),
              yourMove: s.field("yourMove", Schema.Game.move),
              opponentsMove: s.field("opponentsMove", Schema.Game.move),
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
      ~inputSchema=S.object((s): Port.SendMove.input => {
        nickname: s.field("userName", Schema.nickname),
        gameCode: s.field("gameCode", Schema.Game.code),
        yourMove: s.field("move", Schema.Game.move),
      }),
      ~dataSchema=S.unit,
    )
  }
}
