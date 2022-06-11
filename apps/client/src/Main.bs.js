'use strict';

var Api = require("./Api.bs.js");
var FSM = require("./utils/FSM.bs.js");
var AppService = require("./AppService.bs.js");

function run(param) {
  var service = AppService.make(Api.CreateGame.call, Api.JoinGame.call);
  FSM.subscribe(service, (function (state) {
          console.log("STATE", state);
          
        }));
  return FSM.send(service, {
              TAG: /* CreateGame */0,
              userName: "Dmitry"
            });
}

run(undefined);

exports.run = run;
/*  Not a pure module */
