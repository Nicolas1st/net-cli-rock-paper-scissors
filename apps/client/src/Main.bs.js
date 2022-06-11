'use strict';

var Api = require("./Api.bs.js");
var FSM = require("./utils/FSM.bs.js");
var AppService = require("./AppService.bs.js");

function run(param) {
  var service = AppService.make(Api.CreateGame.call, Api.JoinGame.call);
  FSM.subscribe(service, (function (state) {
          var messge;
          if (typeof state === "number") {
            messge = "Menu";
          } else {
            switch (state.TAG | 0) {
              case /* CreatingGame */0 :
                  messge = "CreatingGame {userName: \"" + state.userName + "\"}";
                  break;
              case /* JoiningGame */1 :
                  messge = "JoiningGame {userName: \"" + state.userName + "\", gameCode: \"" + state.gameCode + "\"}";
                  break;
              case /* Game */2 :
                  var gameState = FSM.getCurrentState(state._0);
                  messge = "Game {userName: \"" + gameState.userName + "\", gameCode: \"" + gameState.gameCode + "\"}";
                  break;
              
            }
          }
          console.log("Enter new state", messge);
          
        }));
  return FSM.send(service, {
              TAG: /* CreateGame */0,
              userName: "Dmitry"
            });
}

run(undefined);

exports.run = run;
/*  Not a pure module */
