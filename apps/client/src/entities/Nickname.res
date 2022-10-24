open Stdlib

type t = string

let fromString = string => {
  if string->String.trim !== "" {
    Some(string)
  } else {
    None
  }
}

let toString = Obj.magic
