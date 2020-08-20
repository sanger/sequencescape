import actions from './actions'
import mutations from './mutations'
import getters from './getters'

const state = {
  plates: [],
  // We store batches rather than picks, as the latter are a little expensive to
  // generate. This allows the server just to return a list of batches
  // associated with the plate, from which we can look up the relevant lists,
  // or fetch the batch in needed.
  batches: [],
  // We keep track of the pick count to be able to apply a unique colour
  // to each pick. We keep it within VueX to assist with debugging and tracking.
  pickCount: 0,
  // We keep track of our scans to ensure we can display plates in the order
  // in which they were scanned.
  scanCount: 0
}

const store = {
  state,
  mutations,
  actions,
  getters
}

export default store
