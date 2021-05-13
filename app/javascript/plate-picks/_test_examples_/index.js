/**
 * This file contains a number of shared factories.
 * Each factory is function which will return the appropriate object.
 * This ensures each use of the factory is isolated.
 * It also lets us pass in an optional object to merge in and replace the default arguments
 *
 * Usage:
 * import { emptyBatch, plateWithoutPicks, pendingScannedPlate, pick1 } from '../_test_examples_'
 *
 * const testBatch = emptyBatch({... customArgs })
 *
 * DEPRECATING THESE
 * Setting up a new set below with more consistent names
 */
export const exampleBarcode = "DN12345R";
export const pick1 = (args = {}) => ({ id: 1, name: "Pick 1", short: "Basket 1", ...args });
export const pick2 = (args = {}) => ({ id: 2, name: "Pick 2", short: "Basket 2", ...args });
export const pendingScannedPlate = (args) => ({
  barcode: exampleBarcode,
  scanned: true,
  ...args,
});
export const plateWithoutPicks = (args) => ({
  barcode: exampleBarcode,
  batches: ["1", "2", "3"],
  control: false,
  ...args,
});
export const plateWithPicks = (args) => ({
  ...plateWithoutPicks(),
  picks: { 1: [pick1()], 2: [pick2()] },
  control: false,
  ...args,
});
export const emptyBatch = (args) => ({ id: 1234, picks: [], ...args });

/**
 * PREFER THESE
 *
 * We have a consistent naming convention to ensure the correct assumptions are made
 * api... represents an object as returned by the API
 * store... represents the object as returned by the store
 * denorm... represents denormalized data
 */
export const basePick = ({ id }) => {
  return {
    id,
    name: `Pick ${id}`,
    short: `Basket ${id}`,
    plates: [],
  };
};

export const storePlateWithPicks = (args) => ({
  ...plateWithoutPicks(),
  picks: { 1: [pick1()], 2: [pick2()] },
  control: false,
  ...args,
});

export const example = {
  /**
   * The example namespace describes a fixed series of plates and picks used
   * throughout the tests to maintain consistent data. It consists of four
   * plates, split across two batches. It is structured as follows:
   *
   * Batch 1:
   *  Pick 1: [Plate 1, Plate 2]
   *  Pick 2: [Plate 3, plate 4]
   * Batch 2:
   *  Pick 3: [Plate 4]
   *
   * Batch 2 has not been retrieved in this scenario, so has no associated
   * factories
   *
   * As these factories describe a fixed scenario, they don't take arguments
   */
  storePlate1: (_) => ({ id: "1", barcode: "DN12345R", scanned: null, picks: { 1: [{ id: "1" }] }, batches: ["1"] }),
  storePlate2: (_) => ({ id: "2", barcode: "DN12346S", scanned: true, picks: { 1: [{ id: "1" }] }, batches: ["1"] }),
  storePlate3: (_) => ({ id: "3", barcode: "DN12347T", scanned: true, picks: { 1: [{ id: "2" }] }, batches: ["1"] }),
  storePlate4: (_) => ({
    id: "4",
    barcode: "DN12348U",
    scanned: true,
    picks: { 1: [{ id: "2" }] },
    batches: ["1", "2"],
  }),
  storeBatch1: (_) => ({ id: "1", picks: ["1", "2"] }),
  storePick1: (_) => ({
    ...basePick({ id: 1 }),
    plates: [
      { id: "1", barcode: "DN12345R", batches: ["1"] },
      { id: "2", barcode: "DN12346S", batches: ["1"] },
    ],
  }),
  storePick2: (_) => ({
    ...basePick({ id: 2 }),
    plates: [
      { id: "3", barcode: "DN12347T", batches: ["1"] },
      { id: "4", barcode: "DN12348U", batches: ["1", "2"] },
    ],
  }),
};
