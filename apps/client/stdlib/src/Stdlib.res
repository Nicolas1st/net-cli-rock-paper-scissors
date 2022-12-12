module Array = Stdlib_Array
module Option = Stdlib_Option

module Dict = Js.Dict
module String = Js.String2
module Result = Belt.Result
module Int = Belt.Int
module Json = Js.Json

module Promise = {
  include Promise
}

let log = Js.log
