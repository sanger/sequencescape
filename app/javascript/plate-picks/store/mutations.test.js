import mutations from './mutations'

describe('mutations.js', () => {
  const { updateBatch, updatePlate, addPickToPlate, incrementPick, scanPlate } = mutations

  it('updateBatch', () => {
    // mock state
    const state = { batches: [] }
    const new_batch = { id: 1234, picks: [] }
    // apply mutation
    updateBatch(state, new_batch)
    // assert result
    expect(state.batches).toEqual([new_batch])
  })

  describe('updatePlate', ()=>{
    it('registers a plate if none exists', () => {
      // mock state
      const state = { plates: [] }
      const new_plate = { barcode: 'DN12345', scanned: true }
      // apply mutation
      updatePlate(state, new_plate)
      // assert result
      expect(state.plates).toEqual([{ barcode: 'DN12345', scanned: true }])
    })

    it('updates plates when they exist already', () => {
      // Provided by the browser. We mock it. Currently just mock a string as we're not doing anything fancy
      global.SpeechSynthesisUtterance = class extends String {}
      global.speechSynthesis = { speak: jest.fn() }
      // mock state
      const state = { plates: [{ barcode: 'DN12345', batches: ['1', '2', '3'] }] }
      const new_plate = { barcode: 'DN12345', scanned: true }
      // apply mutation
      updatePlate(state, new_plate)
      // assert result
      expect(state.plates).toEqual([{ barcode: 'DN12345', scanned: true, batches: ['1', '2', '3'] }])
    })
  })

  describe('addPickToPlate', ()=>{
    it('adds a pick to the matching plate', () => {
      const plate = { barcode: 'DN12345', batches: ['1', '2', '3'] }
      const state = { plates: [plate] }
      addPickToPlate(state, { plate: plate, batch: '1', pick: 'Pick' })
      expect(state.plates).toEqual([{ barcode: 'DN12345', batches: ['1', '2', '3'], picks: { 1: ['Pick'] } }])
    })

    it('handles picks from other batches', () => {
      const plate = { barcode: 'DN12345', batches: ['1', '2', '3'], picks: { 1: ['Pick'], 2: ['Other']} }
      const state = { plates: [plate] }
      addPickToPlate(state, { plate: plate, batch: '2', pick: 'New' })
      expect(state.plates).toEqual([{ barcode: 'DN12345', batches: ['1', '2', '3'],
        picks: { 1: ['Pick'], 2: ['Other', 'New'] }
      }])
    })
  })

  describe('incrementPick', ()=>{
    it('keeps track of picks', () => {
      const state = { pickCount: 0 }
      incrementPick(state)
      expect(state.pickCount).toEqual(1)
    })
  })

  describe('scanPlate', () => {
    it('records each plate with the order in which it was scanned', () => {
      // mock state
      const known_plate = { barcode: 'DN12346' }
      const state = { plates: [known_plate], scanCount: 0 }
      const new_plate = { barcode: 'DN12345' }
      // apply mutation
      scanPlate(state, new_plate)
      scanPlate(state, known_plate)
      // assert result
      expect(state.plates).toEqual([{ barcode: 'DN12346', scanned: 2 }, { barcode: 'DN12345', scanned: 1 }])
      expect(state.scanCount).toEqual(2)
    })
  })
})
