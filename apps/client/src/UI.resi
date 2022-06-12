module MultilineText: {
  let make: array<string> => string
}

let message: string => unit

module Input: {
  let prompt: (~message: string, ~parser: string => result<'value, string>) => Promise.t<'value>
}

module List: {
  module Choice: {
    type t<'value>

    let make: (~name: string, ~value: 'value) => t<'value>
  }

  let prompt: (~message: string, ~choices: array<Choice.t<'choice>>) => Promise.t<'choice>
}
