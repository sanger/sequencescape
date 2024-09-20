module.exports = {
  env: {
    browser: true,
    es6: true,
    amd: true,
    "jest/globals": true,
    node: true,
  },
  plugins: ["vue", "jest"],
  extends: ["eslint:recommended", "plugin:vue/recommended", "prettier"],
  parserOptions: {
    parser: "babel-eslint",
    sourceType: "module",
    ecmaVersion: 2018,
  },
  rules: {
    "no-unused-vars": [
      "error",
      {
        vars: "all",
        args: "after-used",
        ignoreRestSiblings: false,
        argsIgnorePattern: "^_",
      },
    ],
  },
};
