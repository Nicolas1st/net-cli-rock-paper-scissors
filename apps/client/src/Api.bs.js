'use strict';

var S = require("rescript-struct/src/S.bs.js");
var Curry = require("rescript/lib/js/curry.js");
var Undici = require("undici");
var Belt_Result = require("rescript/lib/js/belt_Result.js");

var host = "http://localhost:8880";

var unitStruct = S.transformUnknown(S.unknown(undefined), (function (unknown) {
        return {
                TAG: /* Ok */0,
                _0: unknown
              };
      }), undefined, undefined);

function apiCall(path, method, body, bodyStruct, dataStruct) {
  return Undici.request(host + path, {
                  method: method,
                  body: Belt_Result.getExn(S.serializeWith(body, undefined, S.json(bodyStruct)))
                }).then(function (response) {
                return Curry._1(response.body.json, undefined);
              }).then(function (unknown) {
              return Belt_Result.getExn(S.parseWith(unknown, undefined, dataStruct));
            });
}

var bodyStruct = S.record1([
        "userName",
        S.string(undefined)
      ])(undefined, (function (param) {
        return {
                TAG: /* Ok */0,
                _0: param.userName
              };
      }), undefined);

var dataStruct = S.record1([
        "gameCode",
        S.string(undefined)
      ])((function (gameCode) {
        return {
                TAG: /* Ok */0,
                _0: {
                  gameCode: gameCode
                }
              };
      }), undefined, undefined);

function call(userName) {
  return apiCall("/game", "POST", {
              userName: userName
            }, bodyStruct, dataStruct);
}

var CreateGame = {
  bodyStruct: bodyStruct,
  dataStruct: dataStruct,
  call: call
};

var bodyStruct$1 = S.record2([
      [
        "userName",
        S.string(undefined)
      ],
      [
        "gameCode",
        S.string(undefined)
      ]
    ], undefined, (function (param) {
        return {
                TAG: /* Ok */0,
                _0: [
                  param.userName,
                  param.gameCode
                ]
              };
      }), undefined);

function call$1(userName, gameCode) {
  return apiCall("/game/connection", "POST", {
              userName: userName,
              gameCode: gameCode
            }, bodyStruct$1, unitStruct);
}

var JoinGame = {
  bodyStruct: bodyStruct$1,
  call: call$1
};

var bodyStruct$2 = S.record2([
      [
        "userName",
        S.string(undefined)
      ],
      [
        "gameCode",
        S.string(undefined)
      ]
    ], undefined, (function (param) {
        return {
                TAG: /* Ok */0,
                _0: [
                  param.userName,
                  param.gameCode
                ]
              };
      }), undefined);

var backendStatusStruct = S.record1([
        "type",
        S.transform(S.string(undefined), (function (value) {
                if (value === "finished" || value === "inProccess" || value === "waitingForOpponent") {
                  return {
                          TAG: /* Ok */0,
                          _0: value
                        };
                } else {
                  return {
                          TAG: /* Error */1,
                          _0: "The provided status type \"" + value + "\" is unknown"
                        };
                }
              }), undefined, undefined)
      ])((function (backendStatusType) {
        return {
                TAG: /* Ok */0,
                _0: backendStatusType
              };
      }), undefined, undefined);

var moveStruct = S.transform(S.string(undefined), (function (value) {
        switch (value) {
          case "paper" :
              return {
                      TAG: /* Ok */0,
                      _0: /* Paper */2
                    };
          case "rock" :
              return {
                      TAG: /* Ok */0,
                      _0: /* Rock */0
                    };
          case "scissors" :
              return {
                      TAG: /* Ok */0,
                      _0: /* Scissors */1
                    };
          default:
            return {
                    TAG: /* Error */1,
                    _0: "The provided move \"" + value + "\" is unknown"
                  };
        }
      }), undefined, undefined);

var outcomeStruct = S.transform(S.string(undefined), (function (value) {
        switch (value) {
          case "draw" :
              return {
                      TAG: /* Ok */0,
                      _0: /* Draw */0
                    };
          case "loss" :
              return {
                      TAG: /* Ok */0,
                      _0: /* Loss */2
                    };
          case "win" :
              return {
                      TAG: /* Ok */0,
                      _0: /* Win */1
                    };
          default:
            return {
                    TAG: /* Error */1,
                    _0: "The provided outcome \"" + value + "\" is unknown"
                  };
        }
      }), undefined, undefined);

var finishedContextStruct = S.record3([
      [
        "outcome",
        outcomeStruct
      ],
      [
        "yourMove",
        moveStruct
      ],
      [
        "opponentsMove",
        moveStruct
      ]
    ], (function (param) {
        return {
                TAG: /* Ok */0,
                _0: {
                  outcome: param[0],
                  yourMove: param[1],
                  opponentsMove: param[2]
                }
              };
      }), undefined, undefined);

var gameResultStruct = S.record1([
        "gameResult",
        finishedContextStruct
      ])((function (finishedContext) {
        return {
                TAG: /* Ok */0,
                _0: finishedContext
              };
      }), undefined, undefined);

var dataStruct$1 = S.transformUnknown(S.unknown(undefined), (function (unknown) {
        return Belt_Result.flatMap(S.parseWith(unknown, undefined, backendStatusStruct), (function (backendStatusType) {
                      if (backendStatusType === "inProccess") {
                        return {
                                TAG: /* Ok */0,
                                _0: /* InProgress */1
                              };
                      } else if (backendStatusType === "finished") {
                        return Belt_Result.map(S.parseWith(unknown, undefined, gameResultStruct), (function (finishedContext) {
                                      return /* Finished */{
                                              _0: finishedContext
                                            };
                                    }));
                      } else {
                        return {
                                TAG: /* Ok */0,
                                _0: /* WaitingForOpponentJoin */0
                              };
                      }
                    }));
      }), undefined, undefined);

function call$2(userName, gameCode) {
  return apiCall("/status", "GET", {
              userName: userName,
              gameCode: gameCode
            }, bodyStruct$2, dataStruct$1);
}

var RequestGameStatus = {
  bodyStruct: bodyStruct$2,
  backendStatusStruct: backendStatusStruct,
  moveStruct: moveStruct,
  outcomeStruct: outcomeStruct,
  finishedContextStruct: finishedContextStruct,
  gameResultStruct: gameResultStruct,
  dataStruct: dataStruct$1,
  call: call$2
};

exports.host = host;
exports.unitStruct = unitStruct;
exports.apiCall = apiCall;
exports.CreateGame = CreateGame;
exports.JoinGame = JoinGame;
exports.RequestGameStatus = RequestGameStatus;
/* unitStruct Not a pure module */
