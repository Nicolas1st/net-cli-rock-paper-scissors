'use strict';

var FSM = require("./utils/FSM.bs.js");
var Curry = require("rescript/lib/js/curry.js");

var machine = FSM.make((function (state, $$event) {
        if (typeof state === "number") {
          if (state === /* Menu */0 && !(typeof $$event === "number" || $$event.TAG !== /* CreateGame */0)) {
            return {
                    TAG: /* CreatingGame */0,
                    userName: $$event.userName
                  };
          } else {
            return state;
          }
        } else if (state.TAG === /* CreatingGame */0) {
          if (typeof $$event === "number") {
            return /* ErrorScreen */1;
          } else if ($$event.TAG === /* CreateGame */0) {
            return state;
          } else {
            return {
                    TAG: /* Game */1,
                    gameCode: $$event.gameCode
                  };
          }
        } else {
          return state;
        }
      }), /* Menu */0);

function make(requestCreateGame) {
  var service = FSM.interpret(machine);
  FSM.subscribe(service, (function (state) {
            if (typeof state === "number") {
              return ;
            }
            if (state.TAG !== /* CreatingGame */0) {
              return ;
            }
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
            
          }))(undefined);
  return service;
}

exports.machine = machine;
exports.make = make;
/* machine Not a pure module */
