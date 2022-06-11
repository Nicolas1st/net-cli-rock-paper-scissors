'use strict';

var S = require("rescript-struct/src/S.bs.js");
var Js_exn = require("rescript/lib/js/js_exn.js");
var Undici = require("undici");
var Belt_Result = require("rescript/lib/js/belt_Result.js");

var host = "http://localhost:8880";

function unwrapResult(result) {
  if (result.TAG === /* Ok */0) {
    return result._0;
  } else {
    return Js_exn.raiseError(result._0);
  }
}

var unitStruct = S.transformUnknown(S.unknown(undefined), (function (unknown) {
        return {
                TAG: /* Ok */0,
                _0: unknown
              };
      }), undefined, undefined);

function apiCall(path, method, body, bodyStruct, dataStruct) {
  var options_body = unwrapResult(S.serializeWith(body, undefined, S.json(bodyStruct)));
  var options = {
    method: method,
    body: options_body
  };
  return Undici.request(host + path, options).then(function (response) {
                return response.body.json();
              }).then(function (unknown) {
              return unwrapResult(S.parseWith(unknown, undefined, dataStruct));
            });
}

var moveStruct = S.transform(S.string(undefined), (function (data) {
        switch (data) {
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
                    _0: "The provided move \"" + data + "\" is unknown"
                  };
        }
      }), (function (value) {
        var tmp;
        switch (value) {
          case /* Rock */0 :
              tmp = "rock";
              break;
          case /* Scissors */1 :
              tmp = "scissors";
              break;
          case /* Paper */2 :
              tmp = "paper";
              break;
          
        }
        return {
                TAG: /* Ok */0,
                _0: tmp
              };
      }), undefined);

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
  return apiCall("/game/status", "POST", {
              userName: userName,
              gameCode: gameCode
            }, bodyStruct$2, dataStruct$1);
}

var RequestGameStatus = {
  bodyStruct: bodyStruct$2,
  backendStatusStruct: backendStatusStruct,
  outcomeStruct: outcomeStruct,
  finishedContextStruct: finishedContextStruct,
  gameResultStruct: gameResultStruct,
  dataStruct: dataStruct$1,
  call: call$2
};

var bodyStruct$3 = S.record3([
      [
        "userName",
        S.string(undefined)
      ],
      [
        "gameCode",
        S.string(undefined)
      ],
      [
        "move",
        moveStruct
      ]
    ], undefined, (function (param) {
        return {
                TAG: /* Ok */0,
                _0: [
                  param.userName,
                  param.gameCode,
                  param.move
                ]
              };
      }), undefined);

function call$3(userName, gameCode, move) {
  return apiCall("/game/move", "POST", {
              userName: userName,
              gameCode: gameCode,
              move: move
            }, bodyStruct$3, unitStruct);
}

var SendMove = {
  bodyStruct: bodyStruct$3,
  call: call$3
};

exports.host = host;
exports.unwrapResult = unwrapResult;
exports.unitStruct = unitStruct;
exports.apiCall = apiCall;
exports.moveStruct = moveStruct;
exports.CreateGame = CreateGame;
exports.JoinGame = JoinGame;
exports.RequestGameStatus = RequestGameStatus;
exports.SendMove = SendMove;
/* unitStruct Not a pure module */
