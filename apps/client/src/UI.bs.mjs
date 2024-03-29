// Generated by ReScript, PLEASE EDIT WITH CARE

import * as Curry from "rescript/lib/es6/curry.js";
import * as Inquirer from "inquirer";
import * as Stdlib_Result from "@dzakh/rescript-stdlib/src/Stdlib_Result.bs.mjs";

function make(strings) {
  return strings.join("\n");
}

var MultilineText = {
  make: make
};

function message(string) {
  console.clear();
  console.log(string);
}

var _promptName = "promptName";

function prompt(message, parser) {
  return Inquirer.default.prompt([{
                  type: "input",
                  name: _promptName,
                  message: message,
                  validate: (function (input) {
                      var message = Curry._1(parser, input);
                      if (message.TAG === /* Ok */0) {
                        return true;
                      } else {
                        return message._0;
                      }
                    })
                }]).then(function (answer) {
              return Stdlib_Result.getExnWithMessage(Curry._1(parser, answer[_promptName]), "Must be already validated by the validate function.");
            });
}

function make$1(name, value) {
  return {
          name: name,
          value: value
        };
}

var Choice = {
  make: make$1
};

function prompt$1(message, choices) {
  return Inquirer.default.prompt([{
                  type: "list",
                  name: _promptName,
                  message: message,
                  choices: choices
                }]).then(function (answer) {
              return answer[_promptName];
            });
}

var Input = {
  prompt: prompt
};

var List = {
  Choice: Choice,
  prompt: prompt$1
};

export {
  MultilineText ,
  message ,
  Input ,
  List ,
}
/* inquirer Not a pure module */
