@val external _clear: unit => unit = "console.clear"

module MultilineText = {
  let make = strings => {
    strings->Array.join("\n")
  }
}

let message = string => {
  _clear()
  Console.log(string)
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

  @module("inquirer") @scope("default")
  external _prompt: array<Question.t> => Promise.t<Dict.t<string>> = "prompt"

  let prompt = (~message, ~parser) =>
    _prompt([
      {
        questionType: #input,
        message,
        name: _promptName,
        validate: input => {
          switch parser(input) {
          | Ok(_) => true
          | Error(message) => Question.ValidateResult.error(message)
          }
        },
      },
    ])->Promise.thenResolve(answer => {
      answer
      ->Dict.getUnsafe(_promptName)
      ->parser
      ->ResultX.getExnWithMessage("Must be already validated by the validate function.")
    })
}

module List = {
  module Choice = {
    type t<'value> = {
      name: string,
      value: 'value,
    }

    let make = (~name, ~value) => {
      name,
      value,
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

  @module("inquirer") @scope("default")
  external _prompt: array<Question.t<'value>> => Promise.t<Dict.t<'value>> = "prompt"

  let prompt = (~message, ~choices) =>
    _prompt([
      {
        questionType: #list,
        message,
        name: _promptName,
        choices,
      },
    ])->Promise.thenResolve(answer => {
      answer->Dict.getUnsafe(_promptName)
    })
}
