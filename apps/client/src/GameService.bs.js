'use strict';

var FSM = require("./utils/FSM.bs.js");

function make(gameCode, userName) {
  return FSM.interpret(FSM.make((function (state, $$event) {
                    var match = state.screen;
                    if (match !== 3) {
                      return state;
                    } else {
                      return {
                              gameCode: state.gameCode,
                              userName: state.userName,
                              screen: /* SendingPlay */4
                            };
                    }
                  }), {
                  gameCode: gameCode,
                  userName: userName,
                  screen: /* Loading */0
                }));
}

exports.make = make;
/* No side effect */
