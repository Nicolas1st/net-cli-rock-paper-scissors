type t<'state, 'event>
type service<'state, 'event>

let make: (
  ~reducer: (~state: 'state, ~event: 'event) => 'state,
  ~initialState: 'state,
) => t<'state, 'event>

let transition: (t<'state, 'event>, ~state: 'state, ~event: 'event) => 'state

let getInitialState: t<'state, 'event> => 'state

let interpret: t<'state, 'event> => service<'state, 'event>

let send: (service<'state, 'event>, 'event) => unit

let subscribe: (service<'state, 'event>, 'state => unit, unit) => unit

let getCurrentState: service<'state, 'event> => 'state
