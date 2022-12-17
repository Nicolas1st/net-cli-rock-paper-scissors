export default [
  {
    rules: {
      "no-restricted-imports": [
        "error",
        {
          patterns: [
            {
              group: ["*_test.bs.mjs"],
              message: "It's not allowed to import test modules.",
            },
          ],
        },
      ],
    },
  },
];
