@val external _clear: unit => unit = "console.clear"

module MultilineText = {
  let make = strings => {
    strings->Js.Array2.joinWith("\n")
  }
}

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

module Input = {
  module Question = {
    module ValidateResult = {
      type t = bool
      external error: string => t = "%identity"
    }
    type t = {
      @as("type")
      questionType: _questionType,
      name: string,
      message: string,
      validate: string => ValidateResult.t,
    }
  }

  @module("inquirer")
  external _prompt: array<Question.t> => Promise.t<Js.Dict.t<string>> = "prompt"

  let prompt = (~message, ~parser) =>
    _prompt([
      {
        questionType: #input,
        message: message,
        name: _promptName,
        validate: input => {
          switch parser(input) {
          | Ok(_) => true
          | Error(message) => Question.ValidateResult.error(message)
          }
        },
      },
    ])->Promise.thenResolve(answer => {
      answer->Js.Dict.unsafeGet(_promptName)->parser->Belt.Result.getExn
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
