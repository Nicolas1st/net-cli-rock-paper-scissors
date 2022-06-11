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

function call$2(userName, gameCode) {
  return Undici.request(host + "/status", {
                  method: "GET",
                  body: Belt_Result.getExn(S.serializeWith({
                            userName: userName,
                            gameCode: gameCode
                          }, undefined, S.json(bodyStruct$2)))
                }).then(function (response) {
                return Curry._1(response.body.json, undefined);
              }).then(function (param) {
              return {
                      TAG: /* Ok */0,
                      _0: /* WaitingForOpponentJoin */0
                    };
            });
}

var RequestGameStatus = {
  bodyStruct: bodyStruct$2,
  call: call$2
};

exports.host = host;
exports.CreateGame = CreateGame;
exports.JoinGame = JoinGame;
exports.RequestGameStatus = RequestGameStatus;
/* bodyStruct Not a pure module */
