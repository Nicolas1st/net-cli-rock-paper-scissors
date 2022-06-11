@val external _clear: unit => unit = "console.clear"

let message = string => {
  _clear()
  Js.log(string)
}

let _promptName = "promptName"

type _questionType = [
  | #input
  | #number
  | #confirm
  | #list
  | #rawlist
  | #expand
  | #checkbox
  | #password
  | #editor
]

module Confirm = {
  module Question = {
    type t = {
      @as("type")
      questionType: _questionType,
      name: string,
      message: string,
    }
  }

  @module("inquirer")
  external _prompt: array<Question.t> => Promise.t<Js.Dict.t<bool>> = "prompt"

  let prompt = (~message) =>
    _prompt([
      {
        questionType: #confirm,
        message: message,
        name: _promptName,
      },
    ])->Promise.thenResolve(answer => {
      answer->Js.Dict.unsafeGet(_promptName)
    })
}

module List = {
  module Choice = {
    type t<'value> = {
      name: string,
      value: 'value,
    }

    let make = (~name, ~value) => {
      name: name,
      value: value,
    }
  }

  module Question = {
    type t<'value> = {
      @as("type")
      questionType: _questionType,
      name: string,
      message: string,
      choices: array<Choice.t<'value>>,
    }
  }

  @module("inquirer")
  external _prompt: array<Question.t<'value>> => Promise.t<Js.Dict.t<'value>> = "prompt"

  let prompt = (~message, ~choices) =>
    _prompt([
      {
        questionType: #list,
        message: message,
        name: _promptName,
        choices: choices,
      },
    ])->Promise.thenResolve(answer => {
      answer->Js.Dict.unsafeGet(_promptName)
    })
}
