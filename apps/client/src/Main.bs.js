'use strict';

var UI = require("./utils/UI.bs.js");
var Api = require("./Api.bs.js");
var FSM = require("./utils/FSM.bs.js");
var Game = require("./Game.bs.js");
var Curry = require("rescript/lib/js/curry.js");
var Js_exn = require("rescript/lib/js/js_exn.js");
var Nickname = require("./Nickname.bs.js");
var AppService = require("./AppService.bs.js");
var Belt_Option = require("rescript/lib/js/belt_Option.js");

function moveToText(move) {
  switch (move) {
    case /* Rock */0 :
        return "Rock 🪨";
    case /* Scissors */1 :
        return "Scissors ✂️";
    case /* Paper */2 :
        return "Paper 📄";
    
  }
}

function promptUserName(param) {
  return UI.Input.prompt("What's your nickname?", (function (value) {
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
  return UI.Input.prompt("Enter a code of the game you want to join. (Ask it from the creator of the game)", (function (value) {
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
  return UI.List.prompt("Game menu", [
                Curry._2(UI.List.Choice.make, "Create game", "createGame"),
                Curry._2(UI.List.Choice.make, "Join game", "joinGame"),
                Curry._2(UI.List.Choice.make, "Exit", "exit")
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
  UI.message("Creating game...");
  return Promise.resolve(undefined);
}

var CreatingGameRenderer = {
  make: make$1
};

function make$2(param) {
  UI.message("Joining game...");
  return Promise.resolve(undefined);
}

var JoiningGameRenderer = {
  make: make$2
};

function make$3(param) {
  UI.message("Loading game...");
  return Promise.resolve(undefined);
}

var GameLoadingRenderer = {
  make: make$3
};

function make$4(param) {
  UI.message("Waiting when an opponent join the game...");
  return Promise.resolve(undefined);
}

var GameStatusWaitingForOpponentJoinRenderer = {
  make: make$4
};

function make$5(yourMove) {
  UI.message(UI.MultilineText.make([
            "Waiting for the opponent move...",
            "Your move: " + moveToText(yourMove)
          ]));
  return Promise.resolve(undefined);
}

var GameStatusWaitingForOpponentMoveRenderer = {
  make: make$5
};

function make$6(param) {
  UI.message("Ready to play! TODO: add moves");
  return Promise.resolve(undefined);
}

var GameStatusReadyToPlayRenderer = {
  make: make$6
};

function make$7(outcome, yourMove, opponentsMove) {
  var outcomeText;
  switch (outcome) {
    case /* Draw */0 :
        outcomeText = "Draw 🤝";
        break;
    case /* Win */1 :
        outcomeText = "You won 🏆";
        break;
    case /* Loss */2 :
        outcomeText = "You lost 🪦";
        break;
    
  }
  UI.message(UI.MultilineText.make([
            "Game finished!",
            "Outcome: " + outcomeText,
            "Your move: " + moveToText(yourMove),
            "Opponent's move: " + moveToText(opponentsMove)
          ]));
  return Promise.resolve(undefined);
}

var GameStatusFinishedRenderer = {
  make: make$7
};

function renderer(appState) {
  if (typeof appState === "number") {
    return make(undefined);
  }
  switch (appState.TAG | 0) {
    case /* CreatingGame */0 :
        UI.message("Creating game...");
        return Promise.resolve(undefined);
    case /* JoiningGame */1 :
        UI.message("Joining game...");
        return Promise.resolve(undefined);
    case /* Game */2 :
        var match = appState.gameState;
        if (match) {
          var match$1 = match._0;
          if (typeof match$1 === "number") {
            if (match$1 === /* WaitingForOpponentJoin */0) {
              UI.message("Waiting when an opponent join the game...");
              return Promise.resolve(undefined);
            }
            UI.message("Ready to play! TODO: add moves");
            return Promise.resolve(undefined);
          } else {
            if (match$1.TAG === /* WaitingForOpponentMove */0) {
              return make$5(match$1.yourMove);
            }
            var match$2 = match$1._0;
            return make$7(match$2.outcome, match$2.yourMove, match$2.opponentsMove);
          }
        } else {
          UI.message("Loading game...");
          return Promise.resolve(undefined);
        }
    
  }
}

function run(param) {
  var service = AppService.make(Api.CreateGame.call, Api.JoinGame.call, Api.RequestGameStatus.call, Api.SendMove.call);
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

exports.moveToText = moveToText;
exports.ManuRenderer = ManuRenderer;
exports.CreatingGameRenderer = CreatingGameRenderer;
exports.JoiningGameRenderer = JoiningGameRenderer;
exports.GameLoadingRenderer = GameLoadingRenderer;
exports.GameStatusWaitingForOpponentJoinRenderer = GameStatusWaitingForOpponentJoinRenderer;
exports.GameStatusWaitingForOpponentMoveRenderer = GameStatusWaitingForOpponentMoveRenderer;
exports.GameStatusReadyToPlayRenderer = GameStatusReadyToPlayRenderer;
exports.GameStatusFinishedRenderer = GameStatusFinishedRenderer;
exports.renderer = renderer;
exports.run = run;
/*  Not a pure module */
