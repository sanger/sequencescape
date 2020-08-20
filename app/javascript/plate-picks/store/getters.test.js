import getters from './getters'

describe('getters.js', () => {
  const state = {
    plates: [
      { barcode: 'DN12345', scanned: null },
      { barcode: 'DN12346', scanned: 2 },
      { barcode: 'DN12347', scanned: 1 },
      { barcode: 'DN12348', scanned: 3 },
    ]
  }
  const scannedPlatesData = [
    { barcode: 'DN12346', scanned: 2 },
    { barcode: 'DN12347', scanned: 1 },
    { barcode: 'DN12348', scanned: 3 },
  ]
  const { scannedPlates, sortedScannedPlates, scannedPlate, plateWithBarcode } = getters

  describe('scannedPlates', () => {

    it('returns only scanned plates', () => {
      expect(scannedPlates(state)).toContainEqual({ barcode: 'DN12346', scanned: 2 })
      expect(scannedPlates(state)).toContainEqual({ barcode: 'DN12347', scanned: 1 })
      expect(scannedPlates(state)).toContainEqual({ barcode: 'DN12348', scanned: 3 })
      expect(scannedPlates(state)).not.toContainEqual({ barcode: 'DN12345', scanned: null })
    })
  })
  describe('sortedScannedPlates', () => {

    it('returns sorted plates', () => {
      expect(sortedScannedPlates(state, { scannedPlates: scannedPlatesData })).toEqual([
        { barcode: 'DN12347', scanned: 1 },
        { barcode: 'DN12346', scanned: 2 },
        { barcode: 'DN12348', scanned: 3 }
      ])
    })
  })

  describe('scannedPlate', () => {

    it('returns true if a plate is scanned', () => {
      expect(scannedPlate(state, { scannedPlates: scannedPlatesData })('DN12347')).toEqual(true)
    })

    it('returns false if a plate is not scanned', () => {
      expect(scannedPlate(state, { scannedPlates: scannedPlatesData })('DN12345')).toEqual(false)
    })
  })

  describe('plateWithBarcode', () => {
    it('finds a plate', () => {
      expect(plateWithBarcode(state, { scannedPlates: scannedPlatesData })('DN12347')).toEqual({ barcode: 'DN12347', scanned: 1 })
    })
  })
})
