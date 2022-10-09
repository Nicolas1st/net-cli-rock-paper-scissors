%%private(let envSafe = EnvSafe.make())

let apiUrl =
  envSafe->EnvSafe.get(
    ~name="API_URL",
    ~struct=S.string()->S.String.url(),
    ~devFallback="http://localhost:8880",
    (),
  )

envSafe->EnvSafe.close()
