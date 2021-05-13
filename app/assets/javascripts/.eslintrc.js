module.exports = {
  env: {
    browser: true,
    es6: false,
    amd: false,
  },
  plugins: [],
  extends: ["eslint:recommended", "plugin:vue/recommended", "prettier"],
  parserOptions: {
    parser: "babel-eslint",
    sourceType: "module",
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
