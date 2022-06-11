type state = Menu | Game
type event = Create({userName: string})

let reducer = (~state, ~event) => {
  Js.log("foo")
}
