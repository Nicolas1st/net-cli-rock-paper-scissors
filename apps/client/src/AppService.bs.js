'use strict';

var FSM = require("./utils/FSM.bs.js");
var Curry = require("rescript/lib/js/curry.js");
var Caml_obj = require("rescript/lib/js/caml_obj.js");

var JoinGamePort = {};

var CreateGamePort = {};

var SendMovePort = {};

var RequestGameStatusPort = {};

function remoteGameStatusToLocal(remoteGameStatus) {
  if (typeof remoteGameStatus === "number") {
    if (remoteGameStatus !== 0) {
      return /* ReadyToPlay */1;
    } else {
      return /* WaitingForOpponentJoin */0;
    }
  } else {
    return {
            TAG: /* Finished */1,
            _0: remoteGameStatus._0
          };
  }
}

var machine = FSM.make((function (state, $$event) {
        if (state) {
          var tmp = state._0;
          if (typeof tmp === "number") {
            if (tmp !== /* WaitingForOpponentJoin */0 && $$event.TAG !== /* OnGameStatus */0) {
              return /* Status */{
                      _0: {
                        TAG: /* WaitingForOpponentMove */0,
                        yourMove: $$event._0
                      }
                    };
            }
            
          } else if (tmp.TAG === /* WaitingForOpponentMove */0) {
            if ($$event.TAG !== /* OnGameStatus */0) {
              return state;
            }
            var match = $$event._0;
            if (typeof match === "number" && match !== 0) {
              return state;
            }
            
          }
          
        }
        if ($$event.TAG !== /* OnGameStatus */0) {
          return state;
        }
        var gameStatusData = $$event._0;
        var remoteGameStatus = typeof gameStatusData === "number" ? (
            gameStatusData !== 0 ? /* ReadyToPlay */1 : /* WaitingForOpponentJoin */0
          ) : ({
              TAG: /* Finished */1,
              _0: gameStatusData._0
            });
        if (state && !Caml_obj.caml_notequal(state._0, remoteGameStatus)) {
          return state;
        } else {
          return /* Status */{
                  _0: remoteGameStatus
                };
        }
      }), /* Loading */0);

var GameMachine = {
  remoteGameStatusToLocal: remoteGameStatusToLocal,
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
                if (typeof $$event === "number" || $$event.TAG !== /* OnCreateGameSuccess */1) {
                  return state;
                } else {
                  return {
                          TAG: /* Game */2,
                          userName: state.userName,
                          gameCode: $$event.gameCode,
                          gameState: FSM.getInitialState(machine)
                        };
                }
            case /* JoiningGame */1 :
                if (typeof $$event === "number") {
                  return {
                          TAG: /* Game */2,
                          userName: state.userName,
                          gameCode: state.gameCode,
                          gameState: FSM.getInitialState(machine)
                        };
                } else {
                  return state;
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

function make(createGame, joinGame, requestGameStatus, sendMove) {
  var service = FSM.interpret(machine$1);
  FSM.subscribe(service, (function (state) {
          if (typeof state === "number") {
            return ;
          }
          switch (state.TAG | 0) {
            case /* CreatingGame */0 :
                Curry._1(createGame, state.userName).then(function (param) {
                      return FSM.send(service, {
                                  TAG: /* OnCreateGameSuccess */1,
                                  gameCode: param.gameCode
                                });
                    });
                return ;
            case /* JoiningGame */1 :
                Curry._2(joinGame, state.userName, state.gameCode).then(function (param) {
                      return FSM.send(service, /* OnJoinGameSuccess */0);
                    });
                return ;
            case /* Game */2 :
                var match = state.gameState;
                var gameCode = state.gameCode;
                var userName = state.userName;
                if (match) {
                  var match$1 = match._0;
                  if (typeof match$1 === "number") {
                    return ;
                  }
                  if (match$1.TAG !== /* WaitingForOpponentMove */0) {
                    return ;
                  }
                  Curry._3(sendMove, userName, gameCode, match$1.yourMove);
                  return ;
                } else {
                  Curry._2(requestGameStatus, userName, gameCode).then(function (data) {
                        return FSM.send(service, {
                                    TAG: /* GameEvent */3,
                                    _0: {
                                      TAG: /* OnGameStatus */0,
                                      _0: data
                                    }
                                  });
                      });
                  return ;
                }
            
          }
        }));
  return service;
}

exports.JoinGamePort = JoinGamePort;
exports.CreateGamePort = CreateGamePort;
exports.SendMovePort = SendMovePort;
exports.RequestGameStatusPort = RequestGameStatusPort;
exports.GameMachine = GameMachine;
exports.machine = machine$1;
exports.make = make;
/* machine Not a pure module */
