import actions from './actions'
import { startMirage } from '../_mirage_'
import { Response } from 'miragejs'

let mirageServer

beforeEach(() => { mirageServer = startMirage() })
afterEach(() => { mirageServer.shutdown() })

describe('actions.js', () => {
  const { plateBarcodeScan, fetchBatches, fetchBatch } = actions
  describe('plateBarcodeScan', () => {

    it('does not hit the server if all data is present', async () => {
      // mock commit
      const mergedPlate = { barcode: 'DN12345R', picks: { 1: ['Pick 1'], 2: ['Pick 2'] }, batches: [1, 2] }
      const state = {
        plates: [],
        batches: []
      }
      const commit = jest.fn( _ => state.plates = [mergedPlate] )
      // apply action
      await plateBarcodeScan({ commit, state }, 'DN12345R')
      // assert result
      expect(commit).toHaveBeenCalledWith('updatePlate', { barcode: 'DN12345R', scanned: true })
      // And our server shouldn't have been hit
      let requests = mirageServer.pretender.handledRequests
      expect(requests.length).toEqual(0)
    })

    it('fetches plates and batches if needed', async () => {
      // Set up mirage mocks
      mirageServer.create('plate', { barcode: 'DN12345R', batches: [1, 2, 3] })

      // mock commit
      const mergedPlate = { barcode: 'DN12345R', scanned: true }
      const state = { plates: [] }
      const commit = jest.fn(_ => state.plates = [mergedPlate] )
      const dispatch = jest.fn()
      // apply action
      await plateBarcodeScan({ commit, state, dispatch }, 'DN12345R')
      // assert result
      expect(commit).toHaveBeenNthCalledWith(
        1, 'updatePlate', { barcode: 'DN12345R', scanned: true }
      )
      expect(commit).toHaveBeenNthCalledWith(
        2, 'updatePlate', { barcode: 'DN12345R', batches: [1, 2, 3], id: '1' }
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
      expect(commit).toHaveBeenNthCalledWith(
        1, 'updatePlate', { barcode: 'BadPlate', scanned: true }
      )
      expect(commit).toHaveBeenNthCalledWith(
        2, 'updatePlate', { barcode: 'BadPlate', status: 'error', message: 'Internal Server Error: Something went wrong' }
      )
      expect(console.error).toHaveBeenCalled()
    })
  })

  describe('fetchBatches', () => {
    it('fetches each batch`', () => {
      // mock commit
      const commit = jest.fn()
      const dispatch = jest.fn()
      const state = { plates: [], batches: [] }
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
      const batch = {
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

      mirageServer.create('batch', batch)

      // mock commit
      const commit = jest.fn()
      const dispatch = jest.fn()
      const state = { plates: [], batches: [] }
      // apply action
      await fetchBatch({ commit, dispatch, state }, { id: '1' })
      // assert result
      expect(commit).toHaveBeenNthCalledWith(1, 'updateBatch', { id: '1' })
      expect(commit).toHaveBeenNthCalledWith(2, 'updateBatch', batch)
      expect(commit).toHaveBeenCalledWith('addPickToPlate', { plate: { barcode: 'DN12345R', batches: ['1'] }, batch: '1', pick: 'Name 1' })
      expect(commit).toHaveBeenCalledWith('addPickToPlate', { plate: { barcode: 'DN12346S', batches: ['1'] }, batch: '1', pick: 'Name 1' })
      expect(commit).toHaveBeenCalledWith('addPickToPlate', { plate: { barcode: 'DN12347T', batches: ['1'] }, batch: '1', pick: 'Name 2' })
      expect(commit).toHaveBeenCalledWith('addPickToPlate', { plate: { barcode: 'DN12348U', batches: ['1', '2'] }, batch: '1', pick: 'Name 2' })
    })
  })
})
