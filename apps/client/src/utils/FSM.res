module Set = {
  type t<'item>

  @new external make: unit => t<'item> = "Set"
  @send external add: (t<'item>, 'item) => t<'item> = "add"
  @send external delete: (t<'item>, 'item) => bool = "delete"
  @send external forEach: (t<'item>, 'item => unit) => unit = "forEach"
  @send external clear: t<'item> => unit = "clear"
}

type t<'state, 'event> = {
  reducer: (~state: 'state, ~event: 'event) => 'state,
  initialState: 'state,
}
type service<'state, 'event> = {
  fsm: t<'state, 'event>,
  mutable state: 'state,
  mutable isStarted: bool,
  subscribtionSet: Set.t<'state => unit>,
}

let make = (~reducer, ~initialState) => {
  reducer: reducer,
  initialState: initialState,
}

let transition = (machine, ~state, ~event) => {
  machine.reducer(~state, ~event)
}

let getInitialState = machine => machine.initialState

let interpret = machine => {
  {fsm: machine, state: machine.initialState, subscribtionSet: Set.make(), isStarted: false}
}

let send = (service, event) => {
  if service.isStarted {
    let newState = service.fsm->transition(~state=service.state, ~event)
    if newState !== service.state {
      service.state = newState
      service.subscribtionSet->Set.forEach(fn => fn(newState))
    }
  }
}

let subscribe = (service, fn) => {
  service.subscribtionSet->Set.add(fn)->ignore
  () => {
    service.subscribtionSet->Set.delete(fn)->ignore
  }
}

let getCurrentState = service => {
  service.state
}

let start = service => {
  service.isStarted = true
}

let stop = service => {
  service.subscribtionSet->Set.clear
  service.isStarted = false
}
