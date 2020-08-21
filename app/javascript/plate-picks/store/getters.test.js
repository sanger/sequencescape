import getters from './getters'
import defaultState from './state'

describe('getters.js', () => {
  const state = {
    ... defaultState(),
    plates: {
      1: { barcode: 'DN12345', scanned: null },
      2: { barcode: 'DN12346', scanned: true },
      3: { barcode: 'DN12347', scanned: true },
      4: { barcode: 'DN12348', scanned: true },
    },
    scanStore: {
      _DN12347: { barcode: 'DN12347', id: 3 },
      _DN12346: { barcode: 'DN12346', id: 2 },
      _BadPlate: { barcode: '_BadPlate', id: null, errrorMessage: 'Bad' },
      _DN12348: { barcode: 'DN12348', id: 4 }
    }
  }

  const scannedPlatesData = [
    { barcode: 'DN12347', scanned: true, id: 3 },
    { barcode: 'DN12346', scanned: true, id: 2 },
    { barcode: '_BadPlate', id: null, errrorMessage: 'Bad' },
    { barcode: 'DN12348', scanned: true, id: 4 },
  ]

  const { scannedPlates, scannedPlate } = getters

  describe('scannedPlates', () => {
    it('returns sorted scanned plates', () => {
      expect(scannedPlates(state)).toEqual(scannedPlatesData)
    })
  })
})
