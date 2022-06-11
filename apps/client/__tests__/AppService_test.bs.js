'use strict';

var FSM = require("../src/utils/FSM.bs.js");
var Ava = require("ava").default;
var AppService = require("../src/AppService.bs.js");

Ava("Successfully create game and start waiting for player", (function (t) {
        t.plan(9);
        var stepNumberRef = {
          contents: 1
        };
        return new Promise((function (resolve, param) {
                      var service = AppService.make((function (userName) {
                              t.deepEqual(userName, "Dmitry", undefined);
                              return Promise.resolve({
                                          gameCode: "1234"
                                        });
                            }), (function (param, param$1) {
                              return t.fail("Test CreateGameFlow");
                            }), (function (userName, gameCode) {
                              t.deepEqual(userName, "Dmitry", undefined);
                              t.deepEqual(gameCode, "1234", undefined);
                              return Promise.resolve(/* WaitingForOpponentJoin */0);
                            }), (function (param, param$1, param$2) {
                              return t.fail("Test CreateGameFlow");
                            }));
                      FSM.subscribe(service, (function (state) {
                              stepNumberRef.contents = stepNumberRef.contents + 1 | 0;
                              if (typeof state === "number") {
                                if (state === /* Menu */0) {
                                  return ;
                                }
                                t.is(stepNumberRef.contents, 5, undefined);
                                return resolve("");
                              } else {
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
                                          return FSM.send(service, /* Exit */1);
                                        } else {
                                          return ;
                                        }
                                      } else {
                                        t.is(stepNumberRef.contents, 3, undefined);
                                        return ;
                                      }
                                  
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

Ava("Successfully join game and start playing", (function (t) {
        t.plan(17);
        var stepNumberRef = {
          contents: 1
        };
        return new Promise((function (resolve, param) {
                      var service = AppService.make((function (param) {
                              return t.fail("Test JoinGameFlow");
                            }), (function (userName, gameCode) {
                              t.deepEqual(userName, "Dmitry", undefined);
                              t.deepEqual(gameCode, "1234", undefined);
                              return Promise.resolve(undefined);
                            }), (function (userName, gameCode) {
                              t.deepEqual(userName, "Dmitry", undefined);
                              t.deepEqual(gameCode, "1234", undefined);
                              return Promise.resolve(/* InProgress */1);
                            }), (function (userName, gameCode, move) {
                              t.deepEqual(userName, "Dmitry", undefined);
                              t.deepEqual(gameCode, "1234", undefined);
                              t.deepEqual(move, /* Rock */0, undefined);
                              return Promise.resolve(undefined);
                            }));
                      FSM.subscribe(service, (function (state) {
                              stepNumberRef.contents = stepNumberRef.contents + 1 | 0;
                              if (typeof state === "number") {
                                if (state === /* Menu */0) {
                                  return ;
                                }
                                t.is(stepNumberRef.contents, 7, undefined);
                                return resolve("");
                              } else {
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
                                        var match$1 = match._0;
                                        if (typeof match$1 === "number") {
                                          if (match$1 === /* WaitingForOpponentJoin */0) {
                                            return ;
                                          }
                                          t.is(stepNumberRef.contents, 4, undefined);
                                          return FSM.send(service, {
                                                      TAG: /* GameEvent */3,
                                                      _0: {
                                                        TAG: /* SendMove */1,
                                                        _0: /* Rock */0
                                                      }
                                                    });
                                        } else {
                                          if (match$1.TAG === /* WaitingForOpponentMove */0) {
                                            t.deepEqual(match$1.yourMove, /* Rock */0, undefined);
                                            t.is(stepNumberRef.contents, 5, undefined);
                                            return FSM.send(service, {
                                                        TAG: /* GameEvent */3,
                                                        _0: {
                                                          TAG: /* OnGameStatus */0,
                                                          _0: /* Finished */{
                                                            _0: {
                                                              outcome: /* Win */1,
                                                              yourMove: /* Rock */0,
                                                              opponentsMove: /* Scissors */1
                                                            }
                                                          }
                                                        }
                                                      });
                                          }
                                          var match$2 = match$1._0;
                                          t.deepEqual(match$2.yourMove, /* Rock */0, undefined);
                                          t.deepEqual(match$2.opponentsMove, /* Scissors */1, undefined);
                                          t.deepEqual(match$2.outcome, /* Win */1, undefined);
                                          t.is(stepNumberRef.contents, 6, undefined);
                                          return FSM.send(service, /* Exit */1);
                                        }
                                      } else {
                                        t.is(stepNumberRef.contents, 3, undefined);
                                        return ;
                                      }
                                  
                                }
                              }
                            }));
                      t.deepEqual(FSM.getCurrentState(service), /* Menu */0, undefined);
                      return FSM.send(service, {
                                  TAG: /* JoinGame */2,
                                  userName: "Dmitry",
                                  gameCode: "1234"
                                });
                    }));
      }));

/*  Not a pure module */
