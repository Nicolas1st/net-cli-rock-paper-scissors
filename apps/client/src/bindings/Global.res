@val external queueMicrotask: (unit => unit) => unit = "queueMicrotask"

@val
external setTimeout: (unit => unit, int) => int = "setTimeout"

@val
external clearTimeout: int => unit = "clearTimeout"
