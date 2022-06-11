'use strict';

var Api = require("../src/Api.bs.js");
var FSM = require("../src/utils/FSM.bs.js");
var Ava = require("ava").default;
var AppService = require("../src/AppService.bs.js");

Ava("Works", (function (t) {
        var service = AppService.make(Api.CreateGame.call);
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

/*  Not a pure module */
