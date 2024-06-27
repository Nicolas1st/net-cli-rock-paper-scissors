%%private(let envSafe = EnvSafe.make())

let apiUrl = envSafe->EnvSafe.get("API_URL", S.string->S.url, ~devFallback="http://localhost:8880")

envSafe->EnvSafe.close
