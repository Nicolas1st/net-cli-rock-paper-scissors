'use strict';

var Curry = require("rescript/lib/js/curry.js");
var Inquirer = require("inquirer");
var Belt_Option = require("rescript/lib/js/belt_Option.js");

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

var Question = {};

function prompt(message) {
  return Inquirer.prompt([{
                  type: "confirm",
                  name: _promptName,
                  message: message
                }]).then(function (answer) {
              return answer[_promptName];
            });
}

var Confirm = {
  Question: Question,
  prompt: prompt
};

var Question$1 = {};

function prompt$1(message, maybeValidate, param) {
  return Inquirer.prompt([{
                  type: "input",
                  name: _promptName,
                  message: message,
                  validate: Belt_Option.map(maybeValidate, (function (validate, input) {
                          var message = Curry._1(validate, input);
                          if (message.TAG === /* Ok */0) {
                            return true;
                          } else {
                            return message._0;
                          }
                        }))
                }]).then(function (answer) {
              return answer[_promptName];
            });
}

var Input = {
  Question: Question$1,
  prompt: prompt$1
};

function make$1(name, value) {
  return {
          name: name,
          value: value
        };
}

var Choice = {
  make: make$1
};

var Question$2 = {};

function prompt$2(message, choices) {
  return Inquirer.prompt([{
                  type: "list",
                  name: _promptName,
                  message: message,
                  choices: choices
                }]).then(function (answer) {
              return answer[_promptName];
            });
}

var List = {
  Choice: Choice,
  Question: Question$2,
  prompt: prompt$2
};

exports.MultilineText = MultilineText;
exports.message = message;
exports._promptName = _promptName;
exports.Confirm = Confirm;
exports.Input = Input;
exports.List = List;
/* inquirer Not a pure module */
