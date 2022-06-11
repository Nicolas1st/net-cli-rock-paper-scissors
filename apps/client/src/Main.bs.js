'use strict';

var Api = require("./Api.bs.js");
var FSM = require("./utils/FSM.bs.js");
var Curry = require("rescript/lib/js/curry.js");
var Js_exn = require("rescript/lib/js/js_exn.js");
var Inquirer = require("./bindings/Inquirer.bs.js");
var AppService = require("./AppService.bs.js");

function make(param) {
  return Inquirer.List.prompt("Game menu", [
                Curry._2(Inquirer.List.Choice.make, "Create game", "createGame"),
                Curry._2(Inquirer.List.Choice.make, "Join game", "joinGame"),
                Curry._2(Inquirer.List.Choice.make, "Exit", "exit")
              ]).then(function (answer) {
              if (answer === "createGame") {
                return {
                        TAG: /* CreateGame */0,
                        userName: "Hardcoded"
                      };
              } else if (answer === "joinGame") {
                return {
                        TAG: /* JoinGame */2,
                        userName: "Hardcoded",
                        gameCode: "Hardcoded"
                      };
              } else {
                return Js_exn.raiseError("TODO: exit 0");
              }
            });
}

var ManuRenderer = {
  make: make
};

function renderer(appState) {
  if (typeof appState === "number") {
    return make(undefined);
  } else {
    return Inquirer.Confirm.prompt("Unknown state, do you want to exit?").then(function (answer) {
                if (answer) {
                  return Js_exn.raiseError("TODO: exit 0");
                } else {
                  return renderer(appState);
                }
              });
  }
}

function run(param) {
  var service = AppService.make(Api.CreateGame.call, Api.JoinGame.call, Api.RequestGameStatus.call);
  var render = function (state$p) {
    renderer(state$p).then(function (param) {
          return FSM.send(service, param);
        });
    
  };
  FSM.subscribe(service, render);
  return render(FSM.getCurrentState(service));
}

run(undefined);

exports.ManuRenderer = ManuRenderer;
exports.renderer = renderer;
exports.run = run;
/*  Not a pure module */
