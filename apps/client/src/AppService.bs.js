'use strict';

var FSM = require("./utils/FSM.bs.js");
var Curry = require("rescript/lib/js/curry.js");
var Js_exn = require("rescript/lib/js/js_exn.js");
var Caml_obj = require("rescript/lib/js/caml_obj.js");

var JoinGamePort = {};

var CreateGamePort = {};

var RequestGameStatusPort = {};

var machine = FSM.make((function (state, $$event) {
        if (!state) {
          return /* Status */{
                  _0: $$event._0
                };
        }
        var status = $$event._0;
        if (Caml_obj.caml_notequal(state._0, status)) {
          return /* Status */{
                  _0: status
                };
        } else {
          return state;
        }
      }), /* Loading */0);

var GameMachine = {
  machine: machine
};

var machine$1 = FSM.make((function (state, $$event) {
        if (typeof state === "number") {
          if (typeof $$event === "number") {
            return state;
          }
          switch ($$event.TAG | 0) {
            case /* CreateGame */0 :
                return {
                        TAG: /* CreatingGame */0,
                        userName: $$event.userName
                      };
            case /* JoinGame */2 :
                return {
                        TAG: /* JoiningGame */1,
                        userName: $$event.userName,
                        gameCode: $$event.gameCode
                      };
            default:
              return state;
          }
        } else {
          switch (state.TAG | 0) {
            case /* CreatingGame */0 :
                if (typeof $$event === "number") {
                  if ($$event === /* OnCreateGameFailure */0) {
                    return /* Menu */0;
                  } else {
                    return state;
                  }
                } else if ($$event.TAG === /* OnCreateGameSuccess */1) {
                  return {
                          TAG: /* Game */2,
                          userName: state.userName,
                          gameCode: $$event.gameCode,
                          gameState: FSM.getInitialState(machine)
                        };
                } else {
                  return state;
                }
            case /* JoiningGame */1 :
                if (typeof $$event !== "number") {
                  return state;
                }
                switch ($$event) {
                  case /* OnCreateGameFailure */0 :
                      return state;
                  case /* OnJoinGameSuccess */1 :
                      return {
                              TAG: /* Game */2,
                              userName: state.userName,
                              gameCode: state.gameCode,
                              gameState: FSM.getInitialState(machine)
                            };
                  case /* OnJoinGameFailure */2 :
                      return /* Menu */0;
                  
                }
            case /* Game */2 :
                if (typeof $$event === "number" || $$event.TAG !== /* GameEvent */3) {
                  return state;
                } else {
                  return {
                          TAG: /* Game */2,
                          userName: state.userName,
                          gameCode: state.gameCode,
                          gameState: FSM.transition(machine, state.gameState, $$event._0)
                        };
                }
            
          }
        }
      }), /* Menu */0);

function make(createGame, joinGame, requestGameStatus) {
  var service = FSM.interpret(machine$1);
  FSM.subscribe(service, (function (state) {
          if (typeof state === "number") {
            return ;
          }
          switch (state.TAG | 0) {
            case /* CreatingGame */0 :
                Curry._1(createGame, state.userName).then(function (result) {
                      if (result.TAG === /* Ok */0) {
                        return FSM.send(service, {
                                    TAG: /* OnCreateGameSuccess */1,
                                    gameCode: result._0.gameCode
                                  });
                      } else {
                        return FSM.send(service, /* OnCreateGameFailure */0);
                      }
                    });
                return ;
            case /* JoiningGame */1 :
                Curry._2(joinGame, state.userName, state.gameCode).then(function (result) {
                      if (result.TAG === /* Ok */0) {
                        return FSM.send(service, /* OnJoinGameSuccess */1);
                      } else {
                        return FSM.send(service, /* OnJoinGameFailure */2);
                      }
                    });
                return ;
            case /* Game */2 :
                if (state.gameState) {
                  return ;
                } else {
                  Curry._2(requestGameStatus, state.userName, state.gameCode).then(function (result) {
                        if (result.TAG === /* Ok */0) {
                          return FSM.send(service, {
                                      TAG: /* GameEvent */3,
                                      _0: /* OnGameStatus */{
                                        _0: result._0
                                      }
                                    });
                        } else {
                          return Js_exn.raiseError("Smth went wrong");
                        }
                      });
                  return ;
                }
            
          }
        }));
  return service;
}

exports.JoinGamePort = JoinGamePort;
exports.CreateGamePort = CreateGamePort;
exports.RequestGameStatusPort = RequestGameStatusPort;
exports.GameMachine = GameMachine;
exports.machine = machine$1;
exports.make = make;
/* machine Not a pure module */
