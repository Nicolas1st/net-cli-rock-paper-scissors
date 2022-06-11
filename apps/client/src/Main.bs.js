'use strict';

var Api = require("./Api.bs.js");
var FSM = require("./utils/FSM.bs.js");
var Game = require("./Game.bs.js");
var Curry = require("rescript/lib/js/curry.js");
var Js_exn = require("rescript/lib/js/js_exn.js");
var Console = require("./utils/Console.bs.js");
var Js_json = require("rescript/lib/js/js_json.js");
var Nickname = require("./Nickname.bs.js");
var AppService = require("./AppService.bs.js");
var Belt_Option = require("rescript/lib/js/belt_Option.js");

function promptUserName(param) {
  return Console.Input.prompt("What's your nickname?", (function (value) {
                if (Nickname.validate(value)) {
                  return {
                          TAG: /* Ok */0,
                          _0: undefined
                        };
                } else {
                  return {
                          TAG: /* Error */1,
                          _0: "Nickname is invalid"
                        };
                }
              }), undefined);
}

function promptGameCode(param) {
  return Console.Input.prompt("Enter a code of the game you want to join. (Ask it from the creator of the game)", (function (value) {
                if (Game.Code.validate(value)) {
                  return {
                          TAG: /* Ok */0,
                          _0: undefined
                        };
                } else {
                  return {
                          TAG: /* Error */1,
                          _0: "Game code is invalid"
                        };
                }
              }), undefined);
}

function make(param) {
  return Console.List.prompt("Game menu", [
                Curry._2(Console.List.Choice.make, "Create game", "createGame"),
                Curry._2(Console.List.Choice.make, "Join game", "joinGame"),
                Curry._2(Console.List.Choice.make, "Exit", "exit")
              ]).then(function (answer) {
              if (answer === "createGame") {
                return promptUserName(undefined).then(function (userName) {
                            return {
                                    TAG: /* CreateGame */0,
                                    userName: userName
                                  };
                          });
              } else if (answer === "joinGame") {
                return promptUserName(undefined).then(function (userName) {
                            return promptGameCode(undefined).then(function (gameCode) {
                                        return {
                                                TAG: /* JoinGame */2,
                                                userName: userName,
                                                gameCode: gameCode
                                              };
                                      });
                          });
              } else {
                return Js_exn.raiseError("TODO: exit 0");
              }
            });
}

var ManuRenderer = {
  promptUserName: promptUserName,
  promptGameCode: promptGameCode,
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
