/**
 * This file contains a number of shared factories.
 * Each factory is function which will return the appropriate object.
 * This ensures each use of the factory is isolated.
 * It also lets us pass in an optional object to merge in and replace the default arguments
 */
export const exampleBarcode = 'DN12345R'
export const pick1 = (args = {}) => ({ id: 1, name: 'Pick 1', ...args })
export const pick2 = (args = {}) => ({ id: 2, name: 'Pick 2', ...args })
export const pendingScannedPlate = (args) => ({
  barcode: exampleBarcode, scanned: true, ...args
})
export const plateWithoutPicks = (args) => ({
  barcode: exampleBarcode, batches: ['1', '2', '3'], control: false, ...args
})
export const plateWithPicks = (args) => ({
  ...plateWithoutPicks(),
  picks: { 1: [pick1()], 2: [pick2()] },
  control: false, ...args
})
export const emptyBatch = (args) => ({ id: 1234, picks: [], ...args })
