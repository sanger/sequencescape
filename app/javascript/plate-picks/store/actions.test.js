import actions from './actions'
import { startMirage } from '../_mirage_'
let mirageServer;

beforeEach(() => { mirageServer = startMirage() })
afterEach(() => { mirageServer.shutdown() })

describe('actions.js', () => {
  const { plateBarcodeScan, pickScan } = actions
  describe('plateBarcodeScan', () => {

    it('does not hit the server if all data is present', async () => {
      // // Set up mirage mocks

      // // mock commit
      // const commit = jest.fn();
      // const state = {
      //   plates: [
      //     { barcode: 'DN12345R', picks: ['Pick 1'] }
      //   ],
      //   batches: []
      // }
      // // mock dependencies
      // // apply action
      // await plateBarcodeScan({ commit, state }, 'DN12345R')
      // // assert result
      // // expect(commit).toHaveBeenCalledWith(
      // //   'scannedPlate', 'DN12345R'
      // // )
    })

    it('plateBarcodeScan', async () => {
      // Set up mirage mocks
      mirageServer.create("plate", { barcode: "DN12345R", batches: [1, 2, 3] })

      // mock commit
      const commit = jest.fn();
      const state = {
        plates: []
      }
      // mock dependencies
      // apply action
      await plateBarcodeScan({ commit, state }, 'DN12345R')
      // assert result
      // expect(commit).toHaveBeenCalledWith(
      //   'addPlate', { barcode: "DN12345R", batches: [1, 2, 3] }
      // );
    })
  })

  describe('pickScan', () => {

  })
})
