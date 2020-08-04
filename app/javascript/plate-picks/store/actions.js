// Provides backward support for fetch
// If this ends up causing problems in future its probably safe to lose:
// https://caniuse.com/#search=fetch
// Latest versions of chrome (49) and firefox (52.9.0) on windows XP have
// native support, which covers out main need for legacy support.
// So this polyfill will only really be useful for anyone attempting to use IE.
import 'whatwg-fetch'

// Actions handle asynchronous update of state, such as via calls to external apis
// Exported for easy testing. See https://vuex.vuejs.org/guide/testing.html
export default {
  plateBarcodeScan: async ({ commit }, plate_barcode) => {
    console.log('What')
    try {
      const response = await window.fetch('plates/' + plate_barcode, {})
      console.log(response.status)
      commit('addPlate', { 'Ran': 'this' })
    } catch (error) {
      console.error(error)
    }
    console.log('The')
  },
  // A Pick ID scan be:
  // - A scanned Pick barcode
  // - A batch id
  // - A target plate
  pickScan({ commit }, pick_id) {

  }
}
