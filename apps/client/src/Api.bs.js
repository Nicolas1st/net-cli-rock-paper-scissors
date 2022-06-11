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

function call$1(userName, gameCode) {
  return Undici.request(host + "/game", {
                  method: "POST",
                  body: {
                    userName: userName,
                    gameCode: gameCode
                  }
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
  call: call$1
};

exports.host = host;
exports.CreateGame = CreateGame;
exports.JoinGame = JoinGame;
/* bodyStruct Not a pure module */
