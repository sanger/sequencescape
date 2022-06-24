import getters from "./getters";
import defaultState from "./state";
import { example } from "../_test_examples_";

describe("getters.js", () => {
  const pick1 = example.storePick1();
  const pick2 = example.storePick2();

  const plate1 = example.storePlate1();
  const plate2 = example.storePlate2();
  const plate3 = example.storePlate3();
  const plate4 = example.storePlate4();

  const state = {
    ...defaultState(),
    plates: {
      1: plate1,
      2: plate2,
      3: plate3,
      4: plate4,
    },
    scanStore: {
      _DN12347: { barcode: "DN12347", id: 3 },
      _DN12346: { barcode: "DN12346", id: 2 },
      _BadPlate: { barcode: "_BadPlate", id: null, errorMessage: "Bad" },
      _DN12348: { barcode: "DN12348", id: 4 },
    },
    batches: {
      1: example.storeBatch1(),
    },
    picks: {
      1: pick1,
      2: pick2,
    },
  };

  const scannedPlatesData = [
    { barcode: "DN12347", scanned: true, id: 3, batches: ["1"], picks: { 1: [pick2] } },
    { barcode: "DN12346", scanned: true, id: 2, batches: ["1"], picks: { 1: [pick1] } },
    { barcode: "_BadPlate", id: null, errorMessage: "Bad", picks: {} },
    { barcode: "DN12348", scanned: true, id: 4, batches: ["1", "2"], picks: { 1: [pick2] } },
  ];

  const denormalizedBatchData = [
    {
      id: "1",
      picks: [
        { ...pick1, plates: [plate1, plate2] },
        { ...pick2, plates: [plate3, plate4] },
      ],
    },
  ];
  const { scannedPlates, denormalizedBatches } = getters;

  describe("scannedPlates", () => {
    it("returns sorted scanned plates", () => {
      expect(scannedPlates(state)).toEqual(scannedPlatesData);
    });
  });

  describe("denormalizedBatches", () => {
    it("returns batches with inline plates", () => {
      expect(denormalizedBatches(state)).toEqual(denormalizedBatchData);
    });

    it("returns null for picks if there is no pick data", () => {
      const noPickState = {
        ...state,
        batches: {
          1: { id: "1" },
        },
      };
      const noPickDenormalizedBatchData = [{ id: "1" }];
      expect(denormalizedBatches(noPickState)).toEqual(noPickDenormalizedBatchData);
    });
  });
});
