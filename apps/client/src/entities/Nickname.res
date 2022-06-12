type t = string

let validate = string => {
  string->Js.String2.trim !== ""
}

let fromString = string => {
  if string->validate {
    Some(string)
  } else {
    None
  }
}

let unsafeFromString = Obj.magic
let toString = Obj.magic
