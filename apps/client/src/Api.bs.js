'use strict';

var S = require("rescript-struct/src/S.bs.js");
var Curry = require("rescript/lib/js/curry.js");
var Js_exn = require("rescript/lib/js/js_exn.js");
var Undici = require("undici");
var Belt_Result = require("rescript/lib/js/belt_Result.js");

var host = "http://localhost:8880";

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
  return Undici.request(host + "/game", {
                  method: "POST",
                  body: Belt_Result.getExn(S.serializeWith({
                            userName: userName
                          }, undefined, S.json(bodyStruct)))
                }).then(function (response) {
                return Curry._1(response.body.json, undefined);
              }).then(function (unknown) {
              var ok = S.parseWith(unknown, undefined, dataStruct);
              if (ok.TAG === /* Ok */0) {
                return ok;
              } else {
                return Js_exn.raiseError(ok._0);
              }
            });
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
  return Undici.request(host + "/game/connection", {
                  method: "POST",
                  body: Belt_Result.getExn(S.serializeWith({
                            userName: userName,
                            gameCode: gameCode
                          }, undefined, S.json(bodyStruct$1)))
                }).then(function (response) {
                return Curry._1(response.body.json, undefined);
              }).then(function (param) {
              return {
                      TAG: /* Ok */0,
                      _0: undefined
                    };
            });
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

var statusStruct = S.transformUnknown(S.unknown(undefined), (function (unknown) {
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
  return Undici.request(host + "/status", {
                  method: "GET",
                  body: Belt_Result.getExn(S.serializeWith({
                            userName: userName,
                            gameCode: gameCode
                          }, undefined, S.json(bodyStruct$2)))
                }).then(function (response) {
                return Curry._1(response.body.json, undefined);
              }).then(function (unknown) {
              var ok = S.parseWith(unknown, undefined, statusStruct);
              if (ok.TAG === /* Ok */0) {
                return ok;
              } else {
                return Js_exn.raiseError(ok._0);
              }
            });
}

var RequestGameStatus = {
  bodyStruct: bodyStruct$2,
  backendStatusStruct: backendStatusStruct,
  moveStruct: moveStruct,
  outcomeStruct: outcomeStruct,
  finishedContextStruct: finishedContextStruct,
  gameResultStruct: gameResultStruct,
  statusStruct: statusStruct,
  call: call$2
};

exports.host = host;
exports.CreateGame = CreateGame;
exports.JoinGame = JoinGame;
exports.RequestGameStatus = RequestGameStatus;
/* bodyStruct Not a pure module */
