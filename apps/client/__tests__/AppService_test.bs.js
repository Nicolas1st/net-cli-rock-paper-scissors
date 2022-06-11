'use strict';

var FSM = require("../src/utils/FSM.bs.js");
var Ava = require("ava").default;
var Caml_obj = require("rescript/lib/js/caml_obj.js");
var AppService = require("../src/AppService.bs.js");

Ava("Works", (function (t) {
        t.plan(3);
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
                            }));
                      FSM.subscribe(service, (function (state) {
                              if (Caml_obj.caml_equal(state, {
                                      TAG: /* CreatingGame */0,
                                      userName: "Dmitry"
                                    })) {
                                return resolve("");
                              }
                              
                            }));
                      t.deepEqual(FSM.getCurrentState(service), /* Menu */0, undefined);
                      FSM.send(service, {
                            TAG: /* CreateGame */0,
                            userName: "Dmitry"
                          });
                      t.deepEqual(FSM.getCurrentState(service), {
                            TAG: /* CreatingGame */0,
                            userName: "Dmitry"
                          }, undefined);
                      
                    }));
      }));

/*  Not a pure module */
