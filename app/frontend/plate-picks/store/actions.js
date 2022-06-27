// Provides backward support for fetch
// If this ends up causing problems in future its probably safe to lose:
// https://caniuse.com/#search=fetch
// Latest versions of Chrome (49) and Firefox (52.9.0) on windows XP have
// native support, which covers out main need for legacy support.
// So this polyfill will only really be useful for anyone attempting to use IE.
import "whatwg-fetch";

const PLATE_PATH = "/plate_picks/plates/";
const BATCH_PATH = "/plate_picks/batches/";

// Private:
// Extracts pick information from batch and adds it to the plate
async function processPicks({ commit, dispatch }, batch) {
  const pick_ids = [];
  for (const pick of batch.picks) {
    const id = (await dispatch("nextPickId")).toString();
    const new_pick = { ...pick, id, short: `${id}` };
    pick_ids.push(id);
    commit("updatePick", new_pick);
    for (const plate of pick.plates) {
      commit("addPickToPlate", { plate: plate, batch: batch.id, pick: { id } });
    }
  }
  return pick_ids;
}

/**
 * Requests plate_barcode from the server.
 * Note: The catch mainly handles cases where the network or server is
 * inaccessible. If the server responds, even with a status of 5**, fetch
 * treats it as a success.
 * CORS issues also end up getting caught here.
 *
 * @param {String} plate_barcode The barcode of the plate to fetch.
 */
const plateRequest = async (plate_barcode) => {
  try {
    return await window.fetch(PLATE_PATH + encodeURIComponent(plate_barcode), {});
  } catch (error) {
    console.error(error);
    throw `Network Error: ${error.message}`;
  }
};

/**
 * Requests batch_id from the server.
 * Note: The catch mainly handles cases where the network or server is
 * inaccessible. If the server responds, even with a status of 5**, fetch
 * treats it as a success.
 * CORS issues also end up getting caught here.
 *
 * @param {String} batch_id The id of the batch to fetch. A string, rather than a number as that plays nicer with some
 *                          of the expectations of the libraries we're using.
 */
const batchRequest = async (batch_id) => {
  try {
    return await window.fetch(BATCH_PATH + encodeURIComponent(batch_id), {});
  } catch (error) {
    console.error(error);
    throw `Network Error: ${error.message}`;
  }
};

/**
 * Extracts the payload from he response, updates the plate,
 * and triggers requests for any batches associated with the plate.
 * Catch here will deal with cases where the payload from the server isn't
 * json, or doesn't match the format we're expecting.
 *
 * @param {Response} response The response to extract data from
 * @param {Function} commit A Vuex commit function
 * @param {Function} dispatch A Vuex dispatch function
 * @param {String} plate_barcode the barcode of the plate as scanned. Ensures that
 *                               handle cases where the barcode scanned was NOT the
 *                               primary barcode.
 */
const extractPlateJson = async (response) => {
  try {
    const json = await response.json();
    return json.plate;
  } catch (e) {
    console.error(e);
    throw "Unexpected response from the server. Contact support.";
  }
};

/**
 * Extract errors from a response object if available
 * and return an error message
 *
 * @param {Response} response The response to extract errors from
 */
const extractErrors = async (response) => {
  try {
    const json = await response.json();
    console.error("Error response with json", json);
    return `${response.statusText}: ${json.errors}`;
  } catch (e) {
    console.error("Error response without json", e);
    return response.statusText;
  }
};

// Actions handle asynchronous update of state, such as via calls to external apis
// Exported for easy testing. See https://vuex.vuejs.org/guide/testing.html
export default {
  plateBarcodeScan: async ({ commit, dispatch, state }, plate_barcode) => {
    // Firstly we record that the plate has been scanned.
    commit("scanPlate", { barcode: plate_barcode });
    const scanned_plate_id = state.scanStore[`_${plate_barcode}`].id;

    // If we have an id, we don't need to fetch more plate info but we may have
    // batches to fetch
    if (scanned_plate_id) {
      const scanned_plate = state.plates[scanned_plate_id];
      // Don't fetch batches from control plates
      if (!scanned_plate.control) {
        dispatch("fetchBatches", { ids: scanned_plate.batches });
      }
    } else {
      // We've not loaded the plate yet, so go fetch it.
      try {
        const response = await plateRequest(plate_barcode);

        if (response.status === 200) {
          const plate = await extractPlateJson(response);
          commit("updatePlate", { ...plate, scanned: true });
          commit("updateScanPlate", { barcode: plate_barcode, id: plate.id });
          if (!plate.control) {
            dispatch("fetchBatches", { ids: plate.batches });
          }
        } else {
          const error_message = await extractErrors(response);
          throw error_message;
        }
      } catch (error) {
        // We catch and log most expected errors where they occur, and re-throw with
        // a user-friendly error message. This handles displaying that
        commit("updateScanPlate", { barcode: plate_barcode, errorMessage: error });
      }
    }
  },
  fetchBatches({ dispatch }, batch_details) {
    for (const id of batch_details.ids) {
      dispatch("fetchBatch", { id: `${id}` });
    }
  },
  fetchBatch: async ({ commit, state, dispatch }, batch_attributes) => {
    // Add the batch to the list so that we can show a spinner
    const batch_id = batch_attributes.id;
    const existingBatch = state.batches[`b${batch_id}`];
    // We only want to trigger a lookup once, so back out if we already exist.
    if (existingBatch) {
      return;
    }

    // Add the batch to the list so that we can show a spinner
    commit("updateBatch", { id: batch_id });

    try {
      const response = await batchRequest(batch_id);

      if (response.status === 200) {
        const json = await response.json();
        const picks = await processPicks({ commit, dispatch }, json.batch);

        commit("updateBatch", { ...json.batch, picks });
      } else {
        const error_message = await extractErrors(response);
        throw error_message;
      }
    } catch (error) {
      console.error(error);
      commit("updateBatch", { id: batch_id, errorMessage: error });
    }
  },
  nextPickId({ commit, state }) {
    commit("incrementPick");
    return state.pickCount;
  },
};
