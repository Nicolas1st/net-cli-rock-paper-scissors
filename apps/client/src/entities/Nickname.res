type t = string

let fromString = string => {
  if string->Js.String2.trim !== "" {
    Some(string)
  } else {
    None
  }
}

let toString = Obj.magic
