type screen = Loading | WaitingForPlayer | Finished | ReadyToPlay | SendingPlay | WaitingForOpponentPlay
type state = {
  gameCode: string,
  userName: string,
  screen: screen,
}
type event = Play

type t = FSM.service<state, event>

let make = (~gameCode, ~userName) => {
  let machine = FSM.make(~reducer=(~state, ~event) => {
    switch (state.screen, event) {
    | (ReadyToPlay, Play) => {...state, screen: SendingPlay}
    | (_, _) => state
    }
  }, ~initialState={gameCode: gameCode, userName: userName, screen: Loading})
  let service = machine->FSM.interpret
  service
}
