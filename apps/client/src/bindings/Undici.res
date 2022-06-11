module Request = {
  type body = {json: (. unit) => Promise.t<S.unknown>}
  type headers = {@as("content-length") contentLength: string}
  type response = {body: body, statusCode: int, headers: headers}
  type method = [#POST | #GET]
  type options = {method: method, body: string}

  @module("undici")
  external call: (~url: string, ~options: options, unit) => Promise.t<response> = "request"
}
