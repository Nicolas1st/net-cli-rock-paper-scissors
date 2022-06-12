@val @scope("process") external env: {..} = "env"

let apiHost =
  env["API_HOST"]
  ->S.parseWith(S.option(S.string())->S.default("http://localhost:8880"))
  ->ResultX.getExnWithMessage
