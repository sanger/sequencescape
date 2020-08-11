module.exports = {
  'env': {
    'browser': true,
    'es6': true,
    'amd': true,
    'jest/globals': true,
    'node': true
  },
  'plugins': ['vue', 'jest'],
  'extends': [
    'eslint:recommended',
    'plugin:vue/recommended'
  ],
  'parserOptions': {
    'parser': 'babel-eslint',
    'sourceType': 'module'
  },
  'rules': {
    'indent': [
      'error',
      2
    ],
    'linebreak-style': [
      'error',
      'unix'
    ],
    'quotes': [
      'error',
      'single'
    ],
    'semi': [
      'error',
      'never'
    ],
    'no-unused-vars': [
      'error', {
        'vars': 'all',
        'args': 'after-used',
        'ignoreRestSiblings': false,
        'argsIgnorePattern': '^_'
      }
    ]
  }
}
