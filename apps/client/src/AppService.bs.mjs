// Generated by ReScript, PLEASE EDIT WITH CARE

import * as FSM from "./utils/FSM.bs.mjs";
import * as Caml_obj from "rescript/lib/es6/caml_obj.js";
import * as Caml_option from "rescript/lib/es6/caml_option.js";

var machine = FSM.make((function (state, $$event) {
        if (typeof state === "object") {
          var tmp = state._0;
          if (typeof tmp !== "object") {
            if (tmp !== "WaitingForOpponentJoin" && $$event.TAG !== "OnGameStatus") {
              return {
                      TAG: "Status",
                      _0: {
                        TAG: "WaitingForOpponentMove",
                        yourMove: $$event._0
                      }
                    };
            }
            
          } else if (tmp.TAG === "WaitingForOpponentMove") {
            if ($$event.TAG !== "OnGameStatus") {
              return state;
            }
            var tmp$1 = $$event._0;
            if (typeof tmp$1 !== "object" && tmp$1 !== "WaitingForOpponentJoin") {
              return state;
            }
            
          }
          
        }
        if ($$event.TAG !== "OnGameStatus") {
          return state;
        }
        var gameStatusData = $$event._0;
        var remoteGameStatus;
        remoteGameStatus = typeof gameStatusData !== "object" ? (
            gameStatusData === "WaitingForOpponentJoin" ? "WaitingForOpponentJoin" : "ReadyToPlay"
          ) : ({
              TAG: "Finished",
              _0: gameStatusData._0
            });
        if (typeof state !== "object" || Caml_obj.notequal(state._0, remoteGameStatus)) {
          return {
                  TAG: "Status",
                  _0: remoteGameStatus
                };
        } else {
          return state;
        }
      }), "Loading");

var machine$1 = FSM.make((function (state, $$event) {
        if (typeof $$event !== "object" && $$event === "Exit") {
          if (state !== "Exiting") {
            return "Exiting";
          } else {
            return state;
          }
        }
        if (typeof state !== "object") {
          if (state !== "Menu") {
            return state;
          }
          if (typeof $$event !== "object") {
            return state;
          }
          switch ($$event.TAG) {
            case "CreateGame" :
                return {
                        TAG: "CreatingGame",
                        nickname: $$event.nickname
                      };
            case "JoinGame" :
                return {
                        TAG: "JoiningGame",
                        nickname: $$event.nickname,
                        gameCode: $$event.gameCode
                      };
            default:
              return state;
          }
        } else {
          switch (state.TAG) {
            case "CreatingGame" :
                if (typeof $$event !== "object" || $$event.TAG !== "OnCreateGameSuccess") {
                  return state;
                } else {
                  return {
                          TAG: "Game",
                          nickname: state.nickname,
                          gameCode: $$event.gameCode,
                          gameState: FSM.getInitialState(machine)
                        };
                }
            case "JoiningGame" :
                if (typeof $$event !== "object" && $$event === "OnJoinGameSuccess") {
                  return {
                          TAG: "Game",
                          nickname: state.nickname,
                          gameCode: state.gameCode,
                          gameState: FSM.getInitialState(machine)
                        };
                } else {
                  return state;
                }
            case "Game" :
                if (typeof $$event !== "object") {
                  return state;
                }
                if ($$event.TAG !== "GameEvent") {
                  return state;
                }
                var prevGameState = state.gameState;
                var nextGameState = FSM.transition(machine, prevGameState, $$event._0);
                if (Caml_obj.notequal(nextGameState, prevGameState)) {
                  return {
                          TAG: "Game",
                          nickname: state.nickname,
                          gameCode: state.gameCode,
                          gameState: nextGameState
                        };
                } else {
                  return state;
                }
            
          }
        }
      }), "Menu");

function make(createGame, joinGame, requestGameStatus, sendMove) {
  var service = FSM.interpret(machine$1);
  var maybeGameStatusSyncIntervalIdRef = {
    contents: undefined
  };
  var syncGameStatus = function (gameCode, nickname) {
    requestGameStatus({
            nickname: nickname,
            gameCode: gameCode
          }).then(function (data) {
          FSM.send(service, {
                TAG: "GameEvent",
                _0: {
                  TAG: "OnGameStatus",
                  _0: data
                }
              });
        });
  };
  var stopGameStatusSync = function () {
    var gameStatusSyncIntervalId = maybeGameStatusSyncIntervalIdRef.contents;
    if (gameStatusSyncIntervalId !== undefined) {
      clearInterval(Caml_option.valFromOption(gameStatusSyncIntervalId));
      return ;
    }
    
  };
  FSM.subscribe(service, (function (state) {
          if (typeof state !== "object" || state.TAG !== "Game") {
            stopGameStatusSync();
          } else {
            var match = state.gameState;
            var gameCode = state.gameCode;
            var nickname = state.nickname;
            var exit = 0;
            if (typeof match !== "object") {
              exit = 1;
            } else {
              var tmp = match._0;
              if (typeof tmp !== "object" || tmp.TAG !== "Finished") {
                exit = 1;
              } else {
                stopGameStatusSync();
              }
            }
            if (exit === 1) {
              var match$1 = maybeGameStatusSyncIntervalIdRef.contents;
              if (match$1 !== undefined) {
                
              } else {
                syncGameStatus(gameCode, nickname);
                maybeGameStatusSyncIntervalIdRef.contents = Caml_option.some(setInterval((function () {
                            syncGameStatus(gameCode, nickname);
                          }), 3000));
              }
            }
            
          }
          if (typeof state !== "object") {
            if (state === "Menu") {
              return ;
            }
            queueMicrotask(function () {
                  FSM.stop(service);
                });
            return ;
          } else {
            switch (state.TAG) {
              case "CreatingGame" :
                  createGame({
                          nickname: state.nickname
                        }).then(function (param) {
                        FSM.send(service, {
                              TAG: "OnCreateGameSuccess",
                              gameCode: param.gameCode
                            });
                      });
                  return ;
              case "JoiningGame" :
                  joinGame({
                          nickname: state.nickname,
                          gameCode: state.gameCode
                        }).then(function () {
                        FSM.send(service, "OnJoinGameSuccess");
                      });
                  return ;
              case "Game" :
                  var match$2 = state.gameState;
                  if (typeof match$2 !== "object") {
                    return ;
                  }
                  var match$3 = match$2._0;
                  if (typeof match$3 !== "object") {
                    return ;
                  }
                  if (match$3.TAG !== "WaitingForOpponentMove") {
                    return ;
                  }
                  sendMove({
                        nickname: state.nickname,
                        gameCode: state.gameCode,
                        yourMove: match$3.yourMove
                      });
                  return ;
              
            }
          }
        }));
  return service;
}

var GameMachine = {};

export {
  GameMachine ,
  make ,
}
/* machine Not a pure module */
