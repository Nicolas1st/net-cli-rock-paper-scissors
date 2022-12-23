@val external queueMicrotask: (unit => unit) => unit = "queueMicrotask"

@val
external setInterval: (unit => unit, int) => int = "setInterval"

@val
external clearInterval: int => unit = "clearInterval"
