import actions from './actions'
import { startMirage } from '../_mirage_'
import { Response } from 'miragejs'

let mirageServer

beforeEach(() => { mirageServer = startMirage() })
afterEach(() => { mirageServer.shutdown() })

describe('actions.js', () => {
  const { plateBarcodeScan, fetchBatches, fetchBatch, nextPickId } = actions
  describe('plateBarcodeScan', () => {

    it('does not hit the server if all data is present', async () => {
      // mock commit
      const mergedPlate = { barcode: 'DN12345R', picks: { 1: ['Pick 1'], 2: ['Pick 2'] }, batches: [1, 2] }
      const state = {
        plates: [],
        batches: []
      }
      const dispatch = jest.fn()
      const commit = jest.fn( _ => state.plates = [mergedPlate] )
      // apply action
      await plateBarcodeScan({ commit, state, dispatch }, 'DN12345R')
      // assert result
      expect(commit).toHaveBeenCalledWith('scanPlate', { barcode: 'DN12345R' })
      // And our server shouldn't have been hit
      let requests = mirageServer.pretender.handledRequests
      expect(requests.length).toEqual(0)
    })

    it('fetches plates and batches if needed', async () => {
      // Set up mirage mocks
      mirageServer.create('plate', { barcode: 'DN12345R', batches: [1, 2, 3], control: false })

      // mock commit
      const mergedPlate = { barcode: 'DN12345R', scanned: true }
      const state = { plates: [] }
      const commit = jest.fn(_ => state.plates = [mergedPlate] )
      const dispatch = jest.fn()
      // apply action
      await plateBarcodeScan({ commit, state, dispatch }, 'DN12345R')
      // assert result
      expect(commit).toHaveBeenCalledWith('scanPlate', { barcode: 'DN12345R' })
      expect(commit).toHaveBeenNthCalledWith(
        2, 'updatePlate', { barcode: 'DN12345R', batches: [1, 2, 3], id: '1', control: false }
      )

      expect(dispatch).toHaveBeenCalledWith(
        'fetchBatches', { ids: [1, 2, 3] }
      )
    })

    it('records server errors', async () => {
      // Set up mirage mocks
      mirageServer.get('plates/BadPlate', () => {
        return new Response(500, {}, { errors: ['Something went wrong'] })
      })
      // mock the console
      // We don't *need* to do this, but it clutters the output and confuses
      // actual failing tests
      console.error = jest.fn()
      // mock commit
      const mergedPlate = { barcode: 'BadPlate', scanned: true }
      const state = { plates: [] }
      const commit = jest.fn(_ => state.plates = [mergedPlate] )
      // mock dependencies
      // apply action
      await plateBarcodeScan({ commit, state }, 'BadPlate')
      // assert result
      expect(commit).toHaveBeenCalledWith('scanPlate', { barcode: 'BadPlate' })
      expect(commit).toHaveBeenCalledWith(
        'updatePlate', { barcode: 'BadPlate', errorMessage: 'Internal Server Error: Something went wrong' }
      )
      expect(console.error).toHaveBeenCalled()
    })
  })

  describe('fetchBatches', () => {
    it('fetches each batch`', () => {
      // mock commit
      const commit = jest.fn()
      const dispatch = jest.fn()
      const state = { plates: [], batches: [], pickCount: 0 }
      // apply action
      fetchBatches({ commit, dispatch, state }, { ids: [1, 2] })
      // assert result
      expect(dispatch).toHaveBeenCalledWith('fetchBatch', { id: '1' })
      expect(dispatch).toHaveBeenCalledWith('fetchBatch', { id: '2' })
    })
  })

  describe('fetchBatch', () => {
    it('fetches a batch from the server', async () => {
      // Set up mirage mocks
      const returnedBatch = {
        id: '1',
        picks: [
          {
            name: 'Name 1',
            plates: [
              { barcode: 'DN12345R', batches: ['1'] },
              { barcode: 'DN12346S', batches: ['1'] }
            ]
          },
          {
            name: 'Name 2',
            plates: [
              { barcode: 'DN12347T', batches: ['1'] },
              { barcode: 'DN12348U', batches: ['1', '2'] }
            ]
          }
        ]
      }

      const augmentedBatch = {
        id: '1',
        picks: [
          {
            id: 1,
            name: 'Name 1',
            plates: [
              { barcode: 'DN12345R', batches: ['1'] },
              { barcode: 'DN12346S', batches: ['1'] }
            ]
          },
          {
            id: 2,
            name: 'Name 2',
            plates: [
              { barcode: 'DN12347T', batches: ['1'] },
              { barcode: 'DN12348U', batches: ['1', '2'] }
            ]
          }
        ]
      }

      mirageServer.create('batch', returnedBatch)

      // mock commit
      const state = { plates: [], batches: [], pickCount: 0 }
      const commit = jest.fn().mockImplementationOnce(_ => state.batches.push({ id: '1' }))
      const dispatch = jest.fn(_ => state.pickCount += 1)

      // apply action
      await fetchBatch({ commit, dispatch, state }, { id: '1' })
      // assert result
      expect(commit).toHaveBeenCalledWith('updateBatch', { id: '1' })
      expect(commit).toHaveBeenCalledWith('updateBatch', augmentedBatch)
      expect(commit).toHaveBeenCalledWith('addPickToPlate', { plate: { barcode: 'DN12345R', batches: ['1'] }, batch: '1', pick: { name: 'Name 1', id: 1 } })
      expect(commit).toHaveBeenCalledWith('addPickToPlate', { plate: { barcode: 'DN12346S', batches: ['1'] }, batch: '1', pick: { name: 'Name 1', id: 1 } })
      expect(commit).toHaveBeenCalledWith('addPickToPlate', { plate: { barcode: 'DN12347T', batches: ['1'] }, batch: '1', pick: { name: 'Name 2', id: 2 } })
      expect(commit).toHaveBeenCalledWith('addPickToPlate', { plate: { barcode: 'DN12348U', batches: ['1', '2'] }, batch: '1', pick: { name: 'Name 2', id: 2 } })
    })
  })

  describe('nextPickId', () => {
    it('returns an ascending series of integers', async () => {
      // Set up initial state
      const state = { plates: [], batches: [], pickCount: 0 }
      // apply action
      const commit = jest.fn(_ => state.pickCount += 1 )
      const returned = nextPickId({ commit, state })
      expect(commit).toHaveBeenCalledWith('incrementPick')
      expect(returned).toBe(1)
    })
  })
})
