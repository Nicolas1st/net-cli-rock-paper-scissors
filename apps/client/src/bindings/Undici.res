module Request = {
  type body = {json: unit => Promise.t<S.unknown>}
  type response = {body: body}
  type method = [#POST | #GET]
  type options = {method: method, body: string}

  @module("undici")
  external call: (~url: string, ~options: options, unit) => Promise.t<response> = "request"
}
