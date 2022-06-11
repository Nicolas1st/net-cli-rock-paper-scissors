'use strict';

var UI = require("./utils/UI.bs.js");
var Api = require("./Api.bs.js");
var FSM = require("./utils/FSM.bs.js");
var Game = require("./Game.bs.js");
var Curry = require("rescript/lib/js/curry.js");
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

function renderer(appState) {
  if (typeof appState === "number") {
    if (appState === /* Menu */0) {
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
                    return Promise.resolve(/* Exit */1);
                  }
                });
    } else {
      return (process.exit(0));
    }
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
              var gameCode = appState.gameCode;
              UI.message(UI.MultilineText.make([
                        "Waiting when an opponent join the game...",
                        "Game code: \"" + gameCode + "\""
                      ]));
              return Promise.resolve(undefined);
            } else {
              return UI.List.prompt("What's your move?", Game.Move.values.map(function (move) {
                                return Curry._2(UI.List.Choice.make, moveToText(move), move);
                              })).then(function (answer) {
                          return {
                                  TAG: /* GameEvent */3,
                                  _0: {
                                    TAG: /* SendMove */1,
                                    _0: answer
                                  }
                                };
                        });
            }
          }
          if (match$1.TAG === /* WaitingForOpponentMove */0) {
            var yourMove = match$1.yourMove;
            UI.message(UI.MultilineText.make([
                      "Waiting for the opponent move...",
                      "Your move: " + moveToText(yourMove)
                    ]));
            return Promise.resolve(undefined);
          }
          var match$2 = match$1._0;
          var outcome = match$2.outcome;
          var yourMove$1 = match$2.yourMove;
          var opponentsMove = match$2.opponentsMove;
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
                    "Your move: " + moveToText(yourMove$1),
                    "Opponent's move: " + moveToText(opponentsMove)
                  ]));
          return Promise.resolve(undefined);
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

/*  Not a pure module */
