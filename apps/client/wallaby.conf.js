import fs from "fs";

const packageJson = JSON.parse(fs.readFileSync("./package.json", "utf8"));

export default () => ({
  files: ["package.json", "src/**/*.mjs"],
  tests: packageJson.ava.files,
  env: {
    type: "node",
    params: {
      runner: "--experimental-vm-modules",
    },
  },
  debug: false,
  testFramework: "ava",
});
