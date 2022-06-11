'use strict';

var FSM = require("./utils/FSM.bs.js");
var Curry = require("rescript/lib/js/curry.js");

var RequestJoinGame = {};

var RequestCreateGame = {};

var Port = {
  RequestJoinGame: RequestJoinGame,
  RequestCreateGame: RequestCreateGame
};

var machine = FSM.make((function (state, $$event) {
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
                          gameCode: $$event.gameCode,
                          userName: state.userName
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
                              gameCode: state.gameCode,
                              userName: state.userName
                            };
                  case /* OnJoinGameFailure */2 :
                      return /* Menu */0;
                  
                }
            case /* Game */2 :
                return state;
            
          }
        }
      }), /* Menu */0);

function make(requestCreateGame, requestJoinGame) {
  var service = FSM.interpret(machine);
  FSM.subscribe(service, (function (state) {
          if (typeof state === "number") {
            return ;
          }
          switch (state.TAG | 0) {
            case /* CreatingGame */0 :
                Curry._1(requestCreateGame, state.userName).then(function (result) {
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
                Curry._2(requestJoinGame, state.userName, state.gameCode).then(function (result) {
                      if (result.TAG === /* Ok */0) {
                        return FSM.send(service, /* OnJoinGameSuccess */1);
                      } else {
                        return FSM.send(service, /* OnJoinGameFailure */2);
                      }
                    });
                return ;
            case /* Game */2 :
                return ;
            
          }
        }));
  return service;
}

exports.Port = Port;
exports.machine = machine;
exports.make = make;
/* machine Not a pure module */
