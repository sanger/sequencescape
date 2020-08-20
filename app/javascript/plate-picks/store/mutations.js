import Vue from 'vue'
import { say } from '../../libs/speechSynth'

const alertPick = (pick) => { say(pick.name) }
const alertPicks = (picks) => {
  if (picks) {
    for (const pick in Object.values(picks).flat()) { alertPick(pick) }
  }
}

/**
 * Finds the plate in the list with the given barcode
 *
 * @param {String} barcode The barcode of the plate to find
 * @param {Array} list The list of plates to search
 */
const findPlate = (barcode, list) => list.find(list_plate => list_plate.barcode === barcode)

/**
 * Finds the index of a plate in the list with the given barcode
 *
 * @param {String} barcode The barcode of the plate to find
 * @param {Array} list The list of plates to search
 */
const findPlateIndex = (barcode, list) => list.findIndex(list_plate => list_plate.barcode === barcode)

// Mutations handle synchronous update of state.
export default {
  /**
   * Updates a batch with new_attributes, or registers a new batch if it doesn't
   * match an existing batch.
   * Returns the updated batch information (eg. old data merged with new)
   *
   * @param {Object} state The Vuex state object
   * @param {Object} new_attributes The new attributes to be applied the the batch with new_attributes.id
   */
  updateBatch: (state, new_attributes) => {
    const found_batch = state.batches.findIndex(batch => batch.id === new_attributes.id)
    if (found_batch >= 0) {
      // If we've found a new plate, merge the two together and update the original
      // this approach ensures that the properties all remain reactive.
      let combined_batch = Object.assign({}, state.batches[found_batch], new_attributes)
      Vue.set(state.batches, found_batch, combined_batch)
    } else {
      state.batches.push(new_attributes)
    }
  },
  /**
   * Updates a plate with new_attributes, or registers a new
   * plate if it doesn't match an existing plate
   * Returns the updated plate information (eg. old data merged with new)
   *
   * @param {Object} state The Vuex state object
   * @param {Object} new_attributes The new attributes to be applied the the plate with new_attributes.barcode
   */
  updatePlate: (state, new_attributes) => {
    const found_plate = findPlateIndex(new_attributes.barcode, state.plates)
    if (found_plate >= 0) {
      // If we've found a new plate, merge the two together and update the original
      // this approach ensures that the properties all remain reactive.
      let combined_plate = Object.assign({}, state.plates[found_plate], new_attributes)
      Vue.set(state.plates, found_plate, combined_plate)
      if (new_attributes.scanned && !state.plates[found_plate].scanned) { alertPicks(combined_plate.picks) }
    } else {
      state.plates.push(new_attributes)
    }
  },
  /**
  * Adds a new pick to the plate associated with the batch.
  *
  * @param {Object} state The Vuex state object
  * @param {Object} plate The plate to update. (Note: Will find corresponding plate in store according to plate.barcode)
  * @param {String} batch The id of the batch associated with the pick
  * @param {Object} pick {name:,id:} associated with the pick
  */
  addPickToPlate: (state, { plate, batch, pick }) => {
    // Ignore control plates, as they are part of almost every pick.
    if (plate.control) { return }
    let found_plate = findPlate(plate.barcode, state.plates)
    if (found_plate === undefined) { state.plates.push(plate); found_plate = plate }
    if (found_plate.picks === undefined) { Vue.set(found_plate, 'picks', {}) }
    const existing_picks = found_plate.picks[batch] || []
    Vue.set(found_plate.picks, batch, [...existing_picks, pick])
    if (found_plate.scanned) { alertPick(pick) }
  },
  /**
   * Increment the pick counter in order to be able to assign a unique id to each pick
   */
  incrementPick: state => state.pickCount += 1,
  /**
   * Records the the plate with barcode has been scanned
   *
   * @param {Object} state The Vuex state object
   * @param {String} barcode The barcode which has just been scanned
   */
  scanPlate: (state, { barcode }) => {
    state.scanCount += 1
    const found_plate = findPlate(barcode,state.plates)
    if (found_plate) {
      Vue.set(found_plate, 'scanned', state.scanCount)
    } else {
      state.plates.push({ barcode: barcode, scanned: state.scanCount })
    }
  }
}
