'use strict';


function call(userName) {
  return Promise.resolve({
              TAG: /* Ok */0,
              _0: {
                gameCode: "1234"
              }
            });
}

var CreateGame = {
  call: call
};

exports.CreateGame = CreateGame;
/* No side effect */
