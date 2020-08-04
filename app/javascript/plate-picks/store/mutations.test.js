import mutations from './mutations'

describe('mutations.js', () => {
  const { addPlate, addBatch } = mutations
  it('addPlate', () => {
    // mock state
    const state = { plates: [] }
    const new_plate = { barcode: 'DN12345' }
    // apply mutation
    addPlate(state, new_plate)
    // assert result
    expect(state.plates).toEqual([new_plate])
  })

  it('addBatch', () => {
    // mock state
    const state = { batches: [] }
    const new_batch = { id: 1234, picks: [] }
    // apply mutation
    addBatch(state, new_batch)
    // assert result
    expect(state.batches).toEqual([new_batch])
  })
})
