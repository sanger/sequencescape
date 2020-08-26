import getters from './getters'
import defaultState from './state'
import { storePick1, storePick2 } from '../_test_examples_'

describe('getters.js', () => {
  const pick1 = storePick1()
  const pick2 = storePick2()

  const plate1 = { id: '1', barcode: 'DN12345R', scanned: null, picks: { 1: [{ id: '1' }] }, batches: ['1'] }
  const plate2 = { id: '2', barcode: 'DN12346S', scanned: true, picks: { 1: [{ id: '1' }] }, batches: ['1'] }
  const plate3 = { id: '3', barcode: 'DN12347T', scanned: true, picks: { 1: [{ id: '2' }] }, batches: ['1'] }
  const plate4 = { id: '4', barcode: 'DN12348U', scanned: true, picks: { 1: [{ id: '2' }] }, batches: ['1', '2'] }

  const state = {
    ... defaultState(),
    plates: {
      1: plate1, 2: plate2, 3: plate3, 4: plate4
    },
    scanStore: {
      _DN12347: { barcode: 'DN12347', id: 3 },
      _DN12346: { barcode: 'DN12346', id: 2 },
      _BadPlate: { barcode: '_BadPlate', id: null, errorMessage: 'Bad' },
      _DN12348: { barcode: 'DN12348', id: 4 }
    },
    batches: {
      1: { id: '1', picks: ['1','2'] }
    },
    picks: {
      1: pick1,
      2: pick2
    }
  }

  const scannedPlatesData = [
    { barcode: 'DN12347', scanned: true, id: 3, batches: ['1'], picks: { 1: [pick2] } },
    { barcode: 'DN12346', scanned: true, id: 2, batches: ['1'], picks: { 1: [pick1] } },
    { barcode: '_BadPlate', id: null, errorMessage: 'Bad', picks: {} },
    { barcode: 'DN12348', scanned: true, id: 4, batches: ['1', '2'], picks: { 1: [pick2] } },
  ]

  const denormalizedBatchData = [
    {
      id: '1',
      picks: [
        { ...pick1, plates: [plate1, plate2] },
        { ...pick2, plates: [plate3, plate4] }
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
