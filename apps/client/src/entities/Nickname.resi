type t

let fromString: string => option<t>

let unsafeFromString: string => t

let toString: t => string

let validate: string => bool
