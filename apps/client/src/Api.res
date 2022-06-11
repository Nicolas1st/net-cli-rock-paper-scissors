module CreateGame = {
  type data = {gameCode: string}
  let call = (~userName: string) => {
    userName->ignore
    Promise.resolve(Ok({gameCode: "1234"}))
  }
}
