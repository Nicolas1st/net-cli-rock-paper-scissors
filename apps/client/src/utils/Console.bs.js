'use strict';

var Inquirer = require("inquirer");

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

function make(name, value) {
  return {
          name: name,
          value: value
        };
}

var Choice = {
  make: make
};

var Question$1 = {};

function prompt$1(message, choices) {
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
  Question: Question$1,
  prompt: prompt$1
};

exports.message = message;
exports._promptName = _promptName;
exports.Confirm = Confirm;
exports.List = List;
/* inquirer Not a pure module */
