// Mutations handle synchronous update of state.
export default {
  addPlate: (state, plate) => { state.plates.push(plate) },
  addBatch: (state, batch) => { state.batches.push(batch) }
}
