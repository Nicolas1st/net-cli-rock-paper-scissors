@val @scope("process.env") external _maybeApiHost: option<string> = "API_HOST"

let apiHost = _maybeApiHost->Belt.Option.getWithDefault("http://localhost:8880")
