/**
 * Returns a function to denormalize a pick using the
 * provided state object
 * @param {Object} state The Vuex state object
 */
const denormalizedPick = (state) => {
  return (pick) => {
    const plates = pick.plates.map(plate => state.plates[plate.id])
    return {
      ...pick,
      plates
    }
  }
}

// Getters are like computed properties
export default {
  /**
   * Returns an array of all scanned plates in the order in which they were
   * scanned
   * @param {Object} state The Vuex state object
   */
  scannedPlates: (state) => {
    return Object.values(state.scanStore).map((scan) => {
      return { ...state.plates[scan.id], ...scan }
    })
  },
  /**
   * Returns an array of batches with pick and plate information
   * inline. Picks remains undefined if it is absent from the batch.
   * @param {Object} state The Vuex state object
   */
  denormalizedBatches: (state) => {
    return Object.values(state.batches).map((batch) => {
      if (!batch.picks) { return batch }

      const denormalizedPicks = batch.picks.map(denormalizedPick(state))
      return {
        ...batch,
        picks: denormalizedPicks
      }
    })
  }
}
