module Set = {
  type t<'item>

  @new external make: unit => t<'item> = "Set"
  @send external add: (t<'item>, 'item) => t<'item> = "add"
  @send external delete: (t<'item>, 'item) => bool = "delete"
  @send external forEach: (t<'item>, 'item => unit) => unit = "forEach"
}

type t<'state, 'event> = {
  reducer: (~state: 'state, ~event: 'event) => 'state,
  initialState: 'state,
}
type service<'state, 'event> = {
  fsm: t<'state, 'event>,
  mutable state: 'state,
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
  {fsm: machine, state: machine.initialState, subscribtionSet: Set.make()}
}

let send = (service, event) => {
  let newState = service.fsm->transition(~state=service.state, ~event)
  service.state = newState
  service.subscribtionSet->Set.forEach(fn => fn(newState))
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
