// Provides backward support for fetch
// If this ends up causing problems in future its probably safe to lose:
// https://caniuse.com/#search=fetch
// Latest versions of Chrome (49) and Firefox (52.9.0) on windows XP have
// native support, which covers out main need for legacy support.
// So this polyfill will only really be useful for anyone attempting to use IE.
import 'whatwg-fetch'

// Private:
// Extracts pick information from batch
function processPicks(commit, batch) {
  for (const pick of batch.picks) {
    for (const plate of pick.plates) {
      commit('addPickToPlate', { plate: plate, batch: batch.id, pick: pick.name })
    }
  }
}

// Actions handle asynchronous update of state, such as via calls to external apis
// Exported for easy testing. See https://vuex.vuejs.org/guide/testing.html
export default {
  plateBarcodeScan: async ({ commit, dispatch, state }, plate_barcode) => {
    // Firstly we record that the plate has been scanned.
    commit('updatePlate', { barcode: plate_barcode, scanned: true })
    const updated_plate = state.plates.find(plate => plate.barcode === plate_barcode)
    // If we have batch information, we don't need to fetch more info
    if (updated_plate.batches) { return }

    try {
      const response = await window.fetch('plates/' + plate_barcode, {})
      if (response.status===200) {
        const json = await response.json()
        commit('updatePlate', json.plate)
        dispatch('fetchBatches', { ids: json.plate.batches })
      } else {
        console.error(response)

        try {
          const json = await response.json()
          const errorMessage = `${response.statusText}: ${json.errors}`
          commit('updatePlate', { 'barcode': plate_barcode, status: 'error', message: errorMessage })
        } catch {
          commit('updatePlate', { 'barcode': plate_barcode, status: 'error', message: response.statusText })
        }
      }
    } catch (error) {
      console.error(error)
      const errorMessage = `Network Error: ${error.message}`
      commit('updatePlate', { barcode: plate_barcode, status: 'error', message: errorMessage })
    }
  },
  // A Pick ID scan be:
  // - A scanned Pick barcode
  // - A batch id
  // - A target plate
  // pickScan({ commit }, pick_id) {

  // },
  fetchBatches({ dispatch }, batch_details) {
    for( const id of batch_details.ids) {
      dispatch('fetchBatch', { id: `${id}` })
    }
  },
  fetchBatch: async ({ commit, state }, batch_attributes) => {
    // Add the batch to the list so that we can show a spinner
    const batch_id = batch_attributes.id
    commit('updateBatch', { id: batch_id })
    const updated_batch = state.batches.findIndex(batch => batch.id === batch_id)

    if (updated_batch.picks) { return }

    try {
      const response = await window.fetch('batches/' + batch_id, {})
      if (response.status === 200) {
        const json = await response.json()
        commit('updateBatch', json.batch)
        processPicks(commit, json.batch)
      } else {
        console.error(response)

        try {
          const json = await response.json()
          const errorMessage = `${response.statusText}: ${json.errors}`
          commit('updateBatch', { id: batch_id, status: 'error', message: errorMessage })
        } catch {
          commit('updateBatch', { id: batch_id, status: 'error', message: response.statusText })
        }
      }
    } catch (error) {
      console.error(error)
      const errorMessage = `Network Error: ${error.message}`
      commit('updateBatch', { id: batch_id, status: 'error', message: errorMessage })
    }
  }
}
