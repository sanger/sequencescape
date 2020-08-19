import Vue from 'vue'
import { say } from '../../libs/speechSynth'

const alertPick = (pick) => { say(pick.name) }
const alertPicks = (picks) => {
  if (picks) {
    for (const pick in Object.values(picks).flat()) { alertPick(pick) }
  }
}

// Mutations handle synchronous update of state.
export default {
  // Adds a plate to the tracked list of plates.
  addPlate: (state, plate) => { state.plates.push(plate) },
  // Updates a batch with new_attributes, or registers a new
  // batch if it doesn't match an existing batch
  // Returns the updated batch information (eg. old data merged with new)
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
  // Updates a plate with new_attributes, or registers a new
  // plate if it doesn't match an existing plate
  // Returns the updated plate information (eg. old data merged with new)
  updatePlate: (state, new_attributes) => {
    const found_plate = state.plates.findIndex(plate => plate.barcode === new_attributes.barcode)
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
  addPickToPlate: (state, { plate, batch, pick }) => {
    let found_plate = state.plates.find(list_plate => list_plate.barcode === plate.barcode)
    if (found_plate === undefined) { state.plates.push(plate); found_plate = plate }
    if (found_plate.picks === undefined) { Vue.set(found_plate, 'picks', {}) }
    const existing_picks = found_plate.picks[batch] || []
    Vue.set(found_plate.picks, batch, [...existing_picks, pick])
    if (found_plate.scanned) { alertPick(pick) }
  },
  incrementPick: state => state.pickCount += 1
}
