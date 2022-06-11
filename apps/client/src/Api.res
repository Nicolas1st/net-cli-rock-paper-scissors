let host = "0.0.0.0:4000"

module CreateGame = {
  let dataStruct = S.record1(
    ~fields=("gameCode", S.string()),
    ~constructor=gameCode => {AppService.Port.CreateGame.gameCode: gameCode}->Ok,
    (),
  )
  let call: AppService.Port.CreateGame.t = (~userName) => {
    Undici.Request.call(
      ~url=`${host}/game`,
      ~options={method: #POST, body: Obj.magic({"userName": userName})},
      (),
    )
    ->Promise.then(response => response.body.json())
    ->Promise.thenResolve(unknown => {
      switch unknown->S.parseWith(dataStruct) {
      | Ok(_) as ok => ok
      | Error(message) => Js.Exn.raiseError(message)
      }
    })
  }
}
