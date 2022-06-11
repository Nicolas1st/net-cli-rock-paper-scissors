'use strict';

var FSM = require("../src/utils/FSM.bs.js");
var Ava = require("ava").default;
var AppService = require("../src/AppService.bs.js");

Ava("Works", (function (t) {
        t.plan(8);
        var stepNumberRef = {
          contents: 1
        };
        return new Promise((function (resolve, param) {
                      var service = AppService.make((function (userName) {
                              t.deepEqual(userName, "Dmitry", undefined);
                              return Promise.resolve({
                                          TAG: /* Ok */0,
                                          _0: {
                                            gameCode: "1234"
                                          }
                                        });
                            }), (function (param, param$1) {
                              return t.fail("Test CreateGameFlow");
                            }), (function (userName, gameCode) {
                              t.deepEqual(userName, "Dmitry", undefined);
                              t.deepEqual(gameCode, "1234", undefined);
                              return Promise.resolve({
                                          TAG: /* Ok */0,
                                          _0: /* WaitingForOpponentJoin */0
                                        });
                            }));
                      FSM.subscribe(service, (function (state) {
                              stepNumberRef.contents = stepNumberRef.contents + 1 | 0;
                              if (typeof state === "number") {
                                return ;
                              }
                              switch (state.TAG | 0) {
                                case /* CreatingGame */0 :
                                    t.deepEqual(state, {
                                          TAG: /* CreatingGame */0,
                                          userName: "Dmitry"
                                        }, undefined);
                                    t.is(stepNumberRef.contents, 2, undefined);
                                    return ;
                                case /* JoiningGame */1 :
                                    return ;
                                case /* Game */2 :
                                    var match = state.gameState;
                                    if (match) {
                                      if (match._0 === 0) {
                                        t.is(stepNumberRef.contents, 4, undefined);
                                        return resolve("");
                                      } else {
                                        return ;
                                      }
                                    } else {
                                      t.is(stepNumberRef.contents, 3, undefined);
                                      return ;
                                    }
                                
                              }
                            }));
                      t.deepEqual(FSM.getCurrentState(service), /* Menu */0, undefined);
                      return FSM.send(service, {
                                  TAG: /* CreateGame */0,
                                  userName: "Dmitry"
                                });
                    }));
      }));

/*  Not a pure module */
