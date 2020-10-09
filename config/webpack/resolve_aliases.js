/**
 * Resolve aliases provide custom path resolvers.
 * see: https://webpack.js.org/configuration/resolve/#resolvealias
 *
 * Note: aliases begin with @ to help distinguish them from standard paths
 */
const { resolve } = require('path')

module.exports = {
  resolve: {
    alias: {
      '@sharedComponents': resolve('app/javascript/shared/components')
    }
  }
}
