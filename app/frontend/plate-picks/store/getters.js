/**
 * Returns a function to denormalize a pick on batch using the
 * provided state object
 * @param {Object} state The Vuex state object
 */
const denormalizedBatchPick = (state) => {
  return (pickId) => {
    const pick = state.picks[pickId];
    const plates = pick.plates.map((plate) => state.plates[plate.id]);
    return {
      ...pick,
      plates,
    };
  };
};

/**
 * Returns a function to denormalize a pick on plate using the
 * provided state object
 * @param {Object} state The Vuex state object
 */
const denormalizedPlatePick = (state, picks) => {
  const denormalized_picks = {};
  for (const batch_id in picks) {
    const batch_picks = picks[batch_id];
    denormalized_picks[batch_id] = batch_picks.map((pick) => state.picks[pick.id]);
  }
  return denormalized_picks;
};

// Getters are like computed properties
export default {
  /**
   * Returns an array of all scanned plates in the order in which they were
   * scanned, denormalized with pick data
   * @param {Object} state The Vuex state object
   */
  scannedPlates: (state) => {
    return Object.values(state.scanStore).map((scan) => {
      const plate = state.plates[scan.id] || {};
      const picks = denormalizedPlatePick(state, plate.picks);
      return { ...plate, picks, ...scan };
    });
  },
  /**
   * Returns an array of batches with pick and plate information
   * inline. Picks remains undefined if it is absent from the batch.
   * @param {Object} state The Vuex state object
   */
  denormalizedBatches: (state) => {
    return Object.values(state.batches).map((batch) => {
      if (!batch.picks) {
        return batch;
      }

      const denormalizedBatchPicks = batch.picks.map(denormalizedBatchPick(state));
      return {
        ...batch,
        picks: denormalizedBatchPicks,
      };
    });
  },
};
