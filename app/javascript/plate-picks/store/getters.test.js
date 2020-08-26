import getters from './getters'
import defaultState from './state'

describe('getters.js', () => {
  const state = {
    ... defaultState(),
    plates: {
      1: { id: '1', barcode: 'DN12345R', scanned: null },
      2: { id: '2', barcode: 'DN12346S', scanned: true },
      3: { id: '3', barcode: 'DN12347T', scanned: true },
      4: { id: '4', barcode: 'DN12348U', scanned: true },
    },
    scanStore: {
      _DN12347: { barcode: 'DN12347', id: 3 },
      _DN12346: { barcode: 'DN12346', id: 2 },
      _BadPlate: { barcode: '_BadPlate', id: null, errrorMessage: 'Bad' },
      _DN12348: { barcode: 'DN12348', id: 4 }
    },
    batches: {
      1: {
        id: '1',
        picks: [
          {
            id: 1,
            name: 'Name 1',
            plates: [
              { id: '1', barcode: 'DN12345R', batches: ['1'] },
              { id: '2', barcode: 'DN12346S', batches: ['1'] }
            ]
          },
          {
            id: 2,
            name: 'Name 2',
            plates: [
              { id: '3', barcode: 'DN12347T', batches: ['1'] },
              { id: '4', barcode: 'DN12348U', batches: ['1', '2'] }
            ]
          }
        ]
      }
    }
  }

  const scannedPlatesData = [
    { barcode: 'DN12347', scanned: true, id: 3 },
    { barcode: 'DN12346', scanned: true, id: 2 },
    { barcode: '_BadPlate', id: null, errrorMessage: 'Bad' },
    { barcode: 'DN12348', scanned: true, id: 4 },
  ]

  const denormalizedBatchData = [
    {
      id: '1',
      picks: [
        {
          id: 1,
          name: 'Name 1',
          plates: [
            { id: '1', barcode: 'DN12345R', scanned: null },
            { id: '2', barcode: 'DN12346S', scanned: true }
          ]
        },
        {
          id: 2,
          name: 'Name 2',
          plates: [
            { id: '3', barcode: 'DN12347T', scanned: true },
            { id: '4', barcode: 'DN12348U', scanned: true }
          ]
        }
      ]
    }
  ]
  const { scannedPlates, denormalizedBatches } = getters

  describe('scannedPlates', () => {
    it('returns sorted scanned plates', () => {
      expect(scannedPlates(state)).toEqual(scannedPlatesData)
    })
  })

  describe('denormalizedBatches', () => {
    it('returns batches with inline plates', () => {
      expect(denormalizedBatches(state)).toEqual(denormalizedBatchData)
    })

    it('returns null for picks if there is no pick data', () => {
      const noPickState = {
        ...state, batches: {
          1: { id: '1'}
        }
      }
      const noPickDenormalizedBatchData = [{ id: '1' }]
      expect(denormalizedBatches(noPickState)).toEqual(noPickDenormalizedBatchData)
    })
  })
})
