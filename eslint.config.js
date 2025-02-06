import vitest from "eslint-plugin-vitest";
import pluginVue from "eslint-plugin-vue";
import eslintConfigPrettier from "eslint-config-prettier";
import js from "@eslint/js";
import globals from "globals";

export default [
  ...pluginVue.configs["flat/recommended"],
  js.configs.recommended,
  eslintConfigPrettier,
  {
    env: {
      "vitest/env": true,
    },
    files: ["**/*.js,**/*.vue,**/*.cjs"],
    plugins: {
      vitest,
    },
    rules: {
      ...vitest.configs.recommended.rules,
      "vitest/max-nested-describe": ["error", { max: 3 }],
    },
  },
  {
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
  },
  {
    languageOptions: {
      ecmaVersion: "latest",
      sourceType: "module",
      globals: {
        ...vitest.environments.env.globals,
        ...globals.browser,
        ...globals.node,
        // Global vitest and Cypress variables so they don't violate no-undef
        vi: "readonly",
        cy: "readonly",
        Cypress: "readonly",
      },
    },
  },
];

// module.exports = {
//   env: {
//     browser: true,
//     es6: true,
//     amd: true,
//     node: true,
//   },
//   plugins: ["vue", "vitest"],
//   extends: ["eslint:recommended", "plugin:vue/recommended", "prettier"],
//   parserOptions: {
//     sourceType: "module",
//     ecmaVersion: 2018,
//   },
//   rules: {
//     "no-unused-vars": [
//       "error",
//       {
//         vars: "all",
//         args: "after-used",
//         ignoreRestSiblings: false,
//         argsIgnorePattern: "^_",
//       },
//     ],
//   },
// };
