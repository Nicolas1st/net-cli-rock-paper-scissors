let getExnWithMessage = result => {
  switch result {
  | Ok(value) => value
  | Error(message) => Js.Exn.raiseError(message)
  }
}
