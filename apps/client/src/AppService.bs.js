'use strict';

var FSM = require("./utils/FSM.bs.js");
var Curry = require("rescript/lib/js/curry.js");
var GameService = require("./GameService.bs.js");

var JoinGame = {};

var CreateGame = {};

var Port = {
  JoinGame: JoinGame,
  CreateGame: CreateGame
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
                          _0: $$event._0
                        };
                } else {
                  return state;
                }
            case /* JoiningGame */1 :
                if (typeof $$event === "number") {
                  if ($$event === /* OnJoinGameFailure */1) {
                    return /* Menu */0;
                  } else {
                    return state;
                  }
                } else if ($$event.TAG === /* OnJoinGameSuccess */3) {
                  return {
                          TAG: /* Game */2,
                          _0: $$event._0
                        };
                } else {
                  return state;
                }
            case /* Game */2 :
                return state;
            
          }
        }
      }), /* Menu */0);

function make(createGame, joinGame) {
  var service = FSM.interpret(machine);
  FSM.subscribe(service, (function (state) {
          if (typeof state === "number") {
            return ;
          }
          switch (state.TAG | 0) {
            case /* CreatingGame */0 :
                var userName = state.userName;
                Curry._1(createGame, userName).then(function (result) {
                      if (result.TAG === /* Ok */0) {
                        return FSM.send(service, {
                                    TAG: /* OnCreateGameSuccess */1,
                                    _0: GameService.make(result._0.gameCode, userName)
                                  });
                      } else {
                        return FSM.send(service, /* OnCreateGameFailure */0);
                      }
                    });
                return ;
            case /* JoiningGame */1 :
                var gameCode = state.gameCode;
                var userName$1 = state.userName;
                Curry._2(joinGame, userName$1, gameCode).then(function (result) {
                      if (result.TAG === /* Ok */0) {
                        return FSM.send(service, {
                                    TAG: /* OnJoinGameSuccess */3,
                                    _0: GameService.make(gameCode, userName$1)
                                  });
                      } else {
                        return FSM.send(service, /* OnJoinGameFailure */1);
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
