'use strict';

var Api = require("./Api.bs.js");
var FSM = require("./utils/FSM.bs.js");
var Curry = require("rescript/lib/js/curry.js");
var Js_exn = require("rescript/lib/js/js_exn.js");
var Console = require("./utils/Console.bs.js");
var Js_json = require("rescript/lib/js/js_json.js");
var AppService = require("./AppService.bs.js");
var Belt_Option = require("rescript/lib/js/belt_Option.js");

function make(param) {
  return Console.List.prompt("Game menu", [
                Curry._2(Console.List.Choice.make, "Create game", "createGame"),
                Curry._2(Console.List.Choice.make, "Join game", "joinGame"),
                Curry._2(Console.List.Choice.make, "Exit", "exit")
              ]).then(function (answer) {
              return answer === "createGame" ? ({
                          TAG: /* CreateGame */0,
                          userName: "Hardcoded"
                        }) : (
                        answer === "joinGame" ? ({
                              TAG: /* JoinGame */2,
                              userName: "Hardcoded",
                              gameCode: "Hardcoded"
                            }) : Js_exn.raiseError("TODO: exit 0")
                      );
            });
}

var ManuRenderer = {
  make: make
};

function make$1(param) {
  Console.message("Creating game...");
  return Promise.resolve(undefined);
}

var CreatingGameRenderer = {
  make: make$1
};

function renderer(appState) {
  if (typeof appState === "number") {
    return make(undefined);
  }
  switch (appState.TAG | 0) {
    case /* CreatingGame */0 :
        Console.message("Creating game...");
        return Promise.resolve(undefined);
    case /* JoiningGame */1 :
    case /* Game */2 :
        break;
    
  }
  return Console.Confirm.prompt("Unknown state, do you want to exit? (" + Js_json.serializeExn(appState) + ")").then(function (answer) {
              if (answer) {
                return Js_exn.raiseError("TODO: exit 0");
              } else {
                return renderer(appState);
              }
            });
}

function run(param) {
  var service = AppService.make(Api.CreateGame.call, Api.JoinGame.call, Api.RequestGameStatus.call);
  var render = function (state$p) {
    renderer(state$p).then(function (answer) {
          return Belt_Option.map(answer, (function (param) {
                        return FSM.send(service, param);
                      }));
        });
    
  };
  FSM.subscribe(service, render);
  return render(FSM.getCurrentState(service));
}

run(undefined);

exports.ManuRenderer = ManuRenderer;
exports.CreatingGameRenderer = CreatingGameRenderer;
exports.renderer = renderer;
exports.run = run;
/*  Not a pure module */
