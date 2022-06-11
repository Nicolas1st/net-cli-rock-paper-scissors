'use strict';

var Belt_Option = require("rescript/lib/js/belt_Option.js");

var apiHost = Belt_Option.getWithDefault(process.env.API_HOST, "http://localhost:8880");

exports.apiHost = apiHost;
/* apiHost Not a pure module */
