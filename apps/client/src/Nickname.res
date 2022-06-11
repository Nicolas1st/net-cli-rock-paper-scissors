type t = string

let validate = (self: t) => {
  self->Js.String2.trim !== ""
}
