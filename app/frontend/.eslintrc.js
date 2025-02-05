module.exports = {
  env: {
    browser: true,
    es6: true,
    amd: true,
    node: true,
  },
  plugins: ["vue"],
  extends: ["eslint:recommended", "plugin:vue/recommended", "prettier"],
  parserOptions: {
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
