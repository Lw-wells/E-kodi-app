module.exports = {
  root: true,
  env: {
    es6: true,
    node: true,
  },
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
  ],
  parser: "@typescript-eslint/parser",
  parserOptions: {
    project: ["tsconfig.json", "tsconfig.dev.json"],
    sourceType: "module",
  },
  ignorePatterns: [
    "/lib/**/*",
  ],
  plugins: [
    "@typescript-eslint",
  ],
  rules: {
    "@typescript-eslint/no-explicit-any": "off",
    "require-jsdoc": "off",
    "max-len": "off",
    "indent": "off",
    "object-curly-spacing": "off",
    "no-multi-spaces": "off",
    "operator-linebreak": "off",
    "padded-blocks": "off",
    "eol-last": "off",
  },
};



























// module.exports = {
//   root: true,
//   env: {
//     es6: true,
//     node: true,
//   },
//   extends: [
//     "eslint:recommended",
//     "plugin:import/errors",
//     "plugin:import/warnings",
//     "plugin:import/typescript",
//     "google",
//     "plugin:@typescript-eslint/recommended",
//   ],
//   parser: "@typescript-eslint/parser",
//   parserOptions: {
//     project: ["tsconfig.json", "tsconfig.dev.json"],
//     sourceType: "module",
//   },
//   ignorePatterns: [
//     "/lib/**/*", // Ignore built files.
//     "/generated/**/*", // Ignore generated files.
//   ],
//   plugins: [
//     "@typescript-eslint",
//     "import",
//   ],
//   rules: {
//     "quotes": ["error", "double"],
//     "import/no-unresolved": 0,
//     "indent": ["error", 2],
//   },
// };
