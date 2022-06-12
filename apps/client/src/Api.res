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
  Undici.Request.call(~url=`${Env.apiHost}${path}`, ~options, ())
  ->Promise.then(response => {
    if response.headers.contentLength->Belt.Int.fromString->Belt.Option.getWithDefault(0) === 0 {
      Promise.resolve(%raw(`undefined`))
    } else {
      response.body.json(.)
    }
  })
  ->Promise.thenResolve(unknown => {
    unknown->S.parseWith(dataStruct)->ResultX.getExnWithMessage
  })
}

module Struct = {
  let nickname = S.string()->S.transform(
    ~constructor=string =>
      switch string->Nickname.fromString {
      | Some(nickname) => Ok(nickname)
      | None => Error(`Invalid nickname. (${string})`)
      },
    ~destructor=value => value->Nickname.toString->Ok,
    (),
  )

  module Game = {
    let code = S.int()->S.transform(
      ~constructor=int =>
        switch int->Js.Int.toString->Game.Code.fromString {
        | Some(gameCode) => Ok(gameCode)
        | None => Error(`Invalid game code. (${int->Obj.magic})`)
        },
      ~destructor=value => value->Game.Code.toString->Belt.Int.fromString->Belt.Option.getExn->Ok,
      (),
    )

    let move = S.string()->S.transform(
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

    let outcome = S.string()->S.transform(~constructor=value => {
      switch value {
      | "win" => Game.Win->Ok
      | "draw" => Draw->Ok
      | "loss" => Loss->Ok
      | unknownValue => Error(`The provided outcome "${unknownValue}" is unknown`)
      }
    }, ())
  }
}

module CreateGame = {
  type body = {nickname: Nickname.t}

  let bodyStruct = S.record1(
    ~fields=("userName", Struct.nickname),
    ~destructor=({nickname}) => nickname->Ok,
    (),
  )

  let dataStruct = S.record1(
    ~fields=("gameCode", Struct.Game.code),
    ~constructor=gameCode => {AppService.CreateGamePort.gameCode: gameCode}->Ok,
    (),
  )

  let call: AppService.CreateGamePort.t = (~nickname) => {
    apiCall(~path="/game", ~method=#POST, ~bodyStruct, ~dataStruct, ~body={nickname: nickname})
  }
}

module JoinGame = {
  type body = {nickname: Nickname.t, gameCode: Game.Code.t}

  let bodyStruct = S.record2(
    ~fields=(("userName", Struct.nickname), ("gameCode", Struct.Game.code)),
    ~destructor=({nickname, gameCode}) => (nickname, gameCode)->Ok,
    (),
  )

  let dataStruct = S.literal(Unit)

  let call: AppService.JoinGamePort.t = (~nickname, ~gameCode) => {
    apiCall(
      ~path="/game/connection",
      ~method=#POST,
      ~bodyStruct,
      ~dataStruct,
      ~body={nickname: nickname, gameCode: gameCode},
    )
  }
}

module RequestGameStatus = {
  type body = {nickname: Nickname.t, gameCode: Game.Code.t}

  type dataDiscriminant = [#waiting | #inProcess | #finished]

  let dataStruct = {
    let discriminantStruct =
      S.record1(~fields=("status", S.string()->S.transform(~constructor=value => {
            switch Obj.magic(value) {
            | #...dataDiscriminant as dataDiscriminant => dataDiscriminant->Ok
            | unknownValue =>
              Error(`The provided status type "${unknownValue->Obj.magic}" is unknown`)
            }
          }, ())), ~constructor=dataDiscriminant => dataDiscriminant->Ok, ())->S.Record.strip
    let waitingStruct = S.record1(
      ~fields=("status", S.literal(String("waiting"))),
      ~constructor=_ => AppService.RequestGameStatusPort.WaitingForOpponentJoin->Ok,
      (),
    )
    let inProcessStruct = S.record1(
      ~fields=("status", S.literal(String("inProcess"))),
      ~constructor=_ => AppService.RequestGameStatusPort.InProgress->Ok,
      (),
    )
    let finishedStruct = S.record2(
      ~fields=(
        ("status", S.literal(String("finished"))),
        (
          "gameResult",
          S.record3(
            ~fields=(
              ("outcome", Struct.Game.outcome),
              ("yourMove", Struct.Game.move),
              ("opponentsMove", Struct.Game.move),
            ),
            ~constructor=((outcome, yourMove, opponentsMove)) =>
              AppService.RequestGameStatusPort.Finished({
                outcome: outcome,
                yourMove: yourMove,
                opponentsMove: opponentsMove,
              })->Ok,
            (),
          ),
        ),
      ),
      ~constructor=((_, finishedContext)) => finishedContext->Ok,
      (),
    )
    S.dynamic(~constructor=unknown => {
      unknown
      ->S.parseWith(discriminantStruct)
      ->Belt.Result.flatMap(discriminant => {
        switch discriminant {
        | #waiting => waitingStruct
        | #inProcess => inProcessStruct
        | #finished => finishedStruct
        }->Ok
      })
    }, ())
  }

  let bodyStruct = S.record2(
    ~fields=(("userName", Struct.nickname), ("gameCode", Struct.Game.code)),
    ~destructor=({nickname, gameCode}) => (nickname, gameCode)->Ok,
    (),
  )

  let call: AppService.RequestGameStatusPort.t = (~nickname, ~gameCode) => {
    apiCall(
      ~path="/game/status",
      ~method=#POST,
      ~bodyStruct,
      ~dataStruct,
      ~body={nickname: nickname, gameCode: gameCode},
    )
  }
}

module SendMove = {
  type body = {nickname: Nickname.t, gameCode: Game.Code.t, move: Game.Move.t}

  let bodyStruct = S.record3(
    ~fields=(
      ("userName", Struct.nickname),
      ("gameCode", Struct.Game.code),
      ("move", Struct.Game.move),
    ),
    ~destructor=({nickname, gameCode, move}) => (nickname, gameCode, move)->Ok,
    (),
  )

  let dataStruct = S.literal(Unit)

  let call: AppService.SendMovePort.t = (~nickname, ~gameCode, ~move) => {
    apiCall(
      ~path="/game/move",
      ~method=#POST,
      ~bodyStruct,
      ~dataStruct,
      ~body={nickname: nickname, gameCode: gameCode, move: move},
    )
  }
}
