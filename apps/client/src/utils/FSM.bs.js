'use strict';

var Curry = require("rescript/lib/js/curry.js");

function make(reducer, initialState) {
  return {
          reducer: reducer,
          initialState: initialState
        };
}

function transition(machine, state, $$event) {
  return Curry._2(machine.reducer, state, $$event);
}

function getInitialState(machine) {
  return machine.initialState;
}

function interpret(machine) {
  return {
          fsm: machine,
          state: machine.initialState,
          subscribtionSet: new Set()
        };
}

function send(service, $$event) {
  var newState = Curry._2(service.fsm.reducer, service.state, $$event);
  service.state = newState;
  service.subscribtionSet.forEach(function (fn) {
        return Curry._1(fn, newState);
      });
  
}

function subscribe(service, fn) {
  service.subscribtionSet.add(fn);
  return function (param) {
    service.subscribtionSet.delete(fn);
    
  };
}

function getCurrentState(service) {
  return service.state;
}

exports.make = make;
exports.transition = transition;
exports.getInitialState = getInitialState;
exports.interpret = interpret;
exports.send = send;
exports.subscribe = subscribe;
exports.getCurrentState = getCurrentState;
/* No side effect */
