let getExnWithMessage = (x, message) =>
  switch x {
  | Ok(x) => x
  | Error(_) => Js.Exn.raiseError(message)
  }
