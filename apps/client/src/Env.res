@val @scope("process") external env: {..} = "env"

let apiHost =
  env["API_HOST"]
  ->S.parseWith(S.option(S.string())->S.defaulted("http://localhost:8880"))
  ->S.Result.getExn
