'use strict';


var values = [
  /* Rock */0,
  /* Scissors */1,
  /* Paper */2
];

var Move = {
  values: values
};

function validate(self) {
  return self.trim() !== "";
}

var Code = {
  validate: validate
};

exports.Move = Move;
exports.Code = Code;
/* No side effect */
