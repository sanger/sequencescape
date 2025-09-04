import vitest from "eslint-plugin-vitest";
import eslintConfigPrettier from "eslint-config-prettier";
import js from "@eslint/js";
import globals from "globals";

export default [
  js.configs.recommended,
  eslintConfigPrettier,
  {
    env: {
      "vitest/env": true,
    },
    files: ["**/*.js,**/*.cjs"],
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
        // Globals to ensure we don't violate no-undef
        ...vitest.environments.env.globals,
        ...globals.browser,
        ...globals.node,
      },
    },
  },
];
