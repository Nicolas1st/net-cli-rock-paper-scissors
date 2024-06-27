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

let client = Rest.client(~baseUrl=Env.apiUrl)

module CreateGame = {
  let make = (): Port.CreateGame.t => {
    let route = Rest.route(() => {
      path: "/game",
      method: "POST",
      variables: (s): Port.CreateGame.input => {
        nickname: s.field("userName", Schema.nickname),
      },
      responses: [
        (s): Port.CreateGame.data => {
          s.status(#200)
          {
            gameCode: s.field("gameCode", Schema.Game.code),
          }
        },
      ],
    })

    variables => client.call(route, variables)
  }
}

module JoinGame = {
  let make = (): Port.JoinGame.t => {
    let route = Rest.route(() => {
      path: "/game/connection",
      method: "POST",
      variables: (s): Port.JoinGame.input => {
        nickname: s.field("userName", Schema.nickname),
        gameCode: s.field("gameCode", Schema.Game.code),
      },
      responses: [
        s => {
          s.status(#204)
          ()
        },
      ],
    })

    variables => client.call(route, variables)
  }
}

module RequestGameStatus = {
  let make = (): Port.RequestGameStatus.t => {
    let route = Rest.route(() => {
      path: "/game/status",
      method: "POST",
      variables: (s): Port.RequestGameStatus.input => {
        nickname: s.field("userName", Schema.nickname),
        gameCode: s.field("gameCode", Schema.Game.code),
      },
      responses: [
        s => {
          s.status(#200)
          s.data(
            S.union([
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
                  S.object(
                    s => Port.RequestGameStatus.Finished({
                      outcome: s.field("outcome", Schema.Game.outcome),
                      yourMove: s.field("yourMove", Schema.Game.move),
                      opponentsMove: s.field("opponentsMove", Schema.Game.move),
                    }),
                  ),
                )
              }),
            ]),
          )
        },
      ],
    })

    variables => client.call(route, variables)
  }
}

module SendMove = {
  let make = (): Port.SendMove.t => {
    let route = Rest.route(() => {
      path: "/game/move",
      method: "POST",
      variables: (s): Port.SendMove.input => {
        nickname: s.field("userName", Schema.nickname),
        gameCode: s.field("gameCode", Schema.Game.code),
        yourMove: s.field("move", Schema.Game.move),
      },
      responses: [
        s => {
          s.status(#204)
          ()
        },
      ],
    })

    variables => client.call(route, variables)
  }
}
