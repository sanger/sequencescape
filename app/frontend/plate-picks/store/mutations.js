import Vue from "vue";
import { say } from "../../libs/speechSynth";

const alertPick = (state, { id }) => {
  const pick = state.picks[id];
  switch (state.options.notifyMode.mode) {
    case "short":
      say(pick.short);
      break;
    default:
      say(pick.name);
  }
};
const alertPicks = (state, picks) => {
  const curriedPick = (pick) => alertPick(state, pick);
  if (picks) {
    Object.values(picks).flat().forEach(curriedPick);
  }
};

/**
 * Finds the plate in the list with the given barcode
 *
 * @param {Array} list The list of plates to search
 * @param {String} barcode The barcode of the plate to find
 */
const findPlate = (list, { barcode }) => {
  return Object.values(list).find((list_plate) => list_plate.barcode === barcode);
};

// Mutations handle synchronous update of state.
export default {
  /**
   * Updates a batch with new_attributes, or registers a new batch if it doesn't
   * match an existing batch.
   *
   * @param {Object} state The Vuex state object
   * @param {Object} new_attributes The new attributes to be applied the the batch with new_attributes.id
   */
  updateBatch: (state, new_attributes) => {
    // We index with b+id, rather than just id itself, as this maintains insertion order.
    // Solely numeric keys get sorted in numeric order.
    // We can't use a Map, as Vue doesn't handle reactivity properly for Maps.
    const batchIndex = `b${new_attributes.id}`;
    const found_batch = state.batches[batchIndex];
    if (found_batch) {
      // If we've found a new plate, merge the two together and update the original
      // this approach ensures that the properties all remain reactive.
      let combined_batch = Object.assign({}, found_batch, new_attributes);
      Vue.set(state.batches, batchIndex, combined_batch);
    } else {
      Vue.set(state.batches, batchIndex, new_attributes);
    }
  },
  /**
   * Updates a plate with new_attributes, or registers a new
   * plate if it doesn't match an existing plate
   *
   * @param {Object} state The Vuex state object
   * @param {Object} new_attributes The new attributes to be applied the the plate with new_attributes.barcode
   */
  updatePlate: (state, new_attributes) => {
    const found_plate = state.plates[new_attributes.id] || {};
    // Merge the new attributes into the old, and update the plate
    let combined_plate = Object.assign({}, found_plate, new_attributes);
    Vue.set(state.plates, new_attributes.id, combined_plate);
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
    let found_plate = state.plates[plate.id];
    if (found_plate === undefined) {
      Vue.set(state.plates, plate.id, plate);
      found_plate = plate;
    }
    // Ignore control plates, as they are part of almost every pick.
    if (plate.control) {
      return;
    }

    if (found_plate.picks === undefined) {
      Vue.set(found_plate, "picks", {});
    }
    const existing_picks = found_plate.picks[batch] || [];
    Vue.set(found_plate.picks, batch, [...existing_picks, pick]);
    if (found_plate.scanned) {
      alertPick(state, pick);
    }
  },
  /**
   * Increment the pick counter in order to be able to assign a unique id to each pick
   */
  incrementPick: (state) => (state.pickCount += 1),
  /**
   * Updates a pick with new_attributes, or registers a new
   * pick if it doesn't match an existing pick
   *
   * @param {Object} state The Vuex state object
   * @param {Object} new_attributes The new attributes to be applied the the plate with new_attributes.barcode
   */
  updatePick: (state, new_attributes) => {
    const found_pick = state.picks[new_attributes.id] || {};
    // Merge the new attributes into the old, and update the pick
    let combined_pick = Object.assign({}, found_pick, new_attributes);
    Vue.set(state.picks, new_attributes.id, combined_pick);
  },
  /**
   * Records the the plate with barcode has been scanned and references the
   * plate record if its already been found.
   *
   * @param {Object} state The Vuex state object
   * @param {String} barcode The barcode which has just been scanned
   */
  scanPlate: (state, { barcode }) => {
    const found_plate = findPlate(state.plates, { barcode });
    if (found_plate) {
      Vue.set(found_plate, "scanned", true);

      alertPicks(state, found_plate.picks);
    }
    Vue.set(state.scanStore, `_${barcode}`, {
      barcode: barcode,
      id: found_plate?.id || null,
      errorMessage: null,
    });
  },
  /**
   * Updates the scanStore with a reference to the actual plate
   *
   * @param {Object} state The Vuex state object
   * @param {String} barcode The barcode which has just been scanned. It is best if this is pulled from the scan itself,
   *                         rather than the returned record, as this allows the user to scan a non-primary barcode.
   * @param {String} id The id of the found plate
   * @param {String} errorMessage Optional field. Set when the fetch operation fails.
   */
  updateScanPlate: (state, { barcode, id, errorMessage }) => {
    const scan_store_plate = state.scanStore[`_${barcode}`];
    scan_store_plate.id = id || null;
    scan_store_plate.errorMessage = errorMessage || null;
  },
  /**
   * Sets the notifyMode option
   * @param {Object} state The Vuex state object
   * @param {String} value The notify mode. Either short or long
   */
  updateNotifyMode: (state, mode) => {
    state.options.notifyMode = { ...state.options.notifyMode, ...mode };
  },
};
