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
  }
}
