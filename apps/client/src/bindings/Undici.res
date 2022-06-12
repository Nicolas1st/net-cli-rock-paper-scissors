module Response = {
  module Body = {
    type t

    @send
    external json: t => Promise.t<S.unknown> = "json"
  }

  type t = {body: Body.t, statusCode: int, headers: Js.Dict.t<string>}
}

module Request = {
  type method = [#POST | #GET]
  type options = {method: method, body: string}

  @module("undici")
  external call: (~url: string, ~options: options) => Promise.t<Response.t> = "request"
}
