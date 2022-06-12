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
  module Game = {
    let code =
      S.int()->S.transform(
        ~constructor=int => int->Js.Int.toString->Ok,
        ~destructor=value => value->Belt.Int.fromString->Belt.Option.getExn->Ok,
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
  type body = {userName: string}

  let call: AppService.CreateGamePort.t = (~userName) => {
    apiCall(
      ~path="/game",
      ~method=#POST,
      ~bodyStruct=S.record1(
        ~fields=("userName", S.string()),
        ~destructor=({userName}) => userName->Ok,
        (),
      ),
      ~dataStruct=S.record1(
        ~fields=("gameCode", Struct.Game.code),
        ~constructor=gameCode => {AppService.CreateGamePort.gameCode: gameCode}->Ok,
        (),
      ),
      ~body={userName: userName},
    )
  }
}

module JoinGame = {
  type body = {userName: string, gameCode: string}

  let call: AppService.JoinGamePort.t = (~userName, ~gameCode) => {
    apiCall(
      ~path="/game/connection",
      ~method=#POST,
      ~bodyStruct=S.record2(
        ~fields=(("userName", S.string()), ("gameCode", Struct.Game.code)),
        ~destructor=({userName, gameCode}) => (userName, gameCode)->Ok,
        (),
      ),
      ~dataStruct=S.literal(Unit),
      ~body={userName: userName, gameCode: gameCode},
    )
  }
}

module RequestGameStatus = {
  type body = {userName: string, gameCode: string}

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

  let call: AppService.RequestGameStatusPort.t = (~userName, ~gameCode) => {
    apiCall(
      ~path="/game/status",
      ~method=#POST,
      ~bodyStruct=S.record2(
        ~fields=(("userName", S.string()), ("gameCode", Struct.Game.code)),
        ~destructor=({userName, gameCode}) => (userName, gameCode)->Ok,
        (),
      ),
      ~dataStruct,
      ~body={userName: userName, gameCode: gameCode},
    )
  }
}

module SendMove = {
  type body = {userName: string, gameCode: string, move: Game.Move.t}

  let call: AppService.SendMovePort.t = (~userName, ~gameCode, ~move) => {
    apiCall(
      ~path="/game/move",
      ~method=#POST,
      ~bodyStruct=S.record3(
        ~fields=(
          ("userName", S.string()),
          ("gameCode", Struct.Game.code),
          ("move", Struct.Game.move),
        ),
        ~destructor=({userName, gameCode, move}) => (userName, gameCode, move)->Ok,
        (),
      ),
      ~dataStruct=S.literal(Unit),
      ~body={userName: userName, gameCode: gameCode, move: move},
    )
  }
}
