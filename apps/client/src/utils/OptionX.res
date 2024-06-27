let getExnWithMessage = (x, message) =>
  switch x {
  | Some(x) => x
  | None => Js.Exn.raiseError(message)
  }
