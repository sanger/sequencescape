/**
 * This file contains a number of shared factories.
 * Each factory is function which will return the appropriate object.
 * This ensures each use of the factory is isolated.
 * It also lets us pass in an optional object to merge in and replace the default arguments
 *
 * DEPRECATING THESE
 * Setting up a new set below with more consistent names
 */
export const exampleBarcode = 'DN12345R'
export const pick1 = (args = {}) => ({ id: 1, name: 'Pick 1', short: 'Basket 1', ...args })
export const pick2 = (args = {}) => ({ id: 2, name: 'Pick 2', short: 'Basket 2', ...args })
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

/**
 * PREFER THESE
 *
 * We have a consistent naming convention to ensure the correct assumptions are made
 * api... represents an object as returned by the API
 * store... represents the object as returned by the store
 * denorm... represents denormalized data
*/
export const basePick = ({id}) => {
  return {
    id, name: `Pick ${id}`, short: `Basket ${id}`,
    plates: []
  }
}

export const storePick1 = (args = {}) => {
  const id = args.id || 1
  return {
    ...basePick({ id }),
    // TODO: Ideally we'd only store id here
    plates: [
      { id: '1', barcode: 'DN12345R', batches: ['1'] },
      { id: '2', barcode: 'DN12346S', batches: ['1'] }
    ],
    ...args }
}

export const storePick2 = (args = {}) => {
  const id = args.id || 2
  return {
    ...basePick({ id }),
    // TODO: Ideally we'd only store id here
    plates: [
      { id: '3', barcode: 'DN12347T', batches: ['1'] },
      { id: '4', barcode: 'DN12348U', batches: ['1', '2'] }
    ],
    ...args
  }
}
