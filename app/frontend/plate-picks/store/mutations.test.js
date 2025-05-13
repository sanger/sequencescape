import mutations from "./mutations";
import defaultState from "./state";
import { emptyBatch, plateWithoutPicks, pendingScannedPlate, pick1 } from "../_test_examples_";

describe("mutations.js", () => {
  const {
    updateBatch,
    updatePlate,
    addPickToPlate,
    incrementPick,
    scanPlate,
    updateScanPlate,
    updateNotifyMode,
    updatePick,
  } = mutations;

  it("updateBatch", () => {
    // mock state
    const state = defaultState();
    const new_batch = emptyBatch({ id: "1234" });
    // apply mutation
    updateBatch(state, new_batch);
    // assert result
    expect(state.batches).toEqual({ b1234: new_batch });
  });

  describe("updatePlate", () => {
    it("registers a plate if none exists", () => {
      // mock state
      const state = defaultState();
      const new_plate = pendingScannedPlate({ id: 1 });
      // apply mutation
      updatePlate(state, new_plate);
      // assert result
      expect(state.plates).toEqual({ 1: new_plate });
    });

    it("updates plates when they exist already", () => {
      // Provided by the browser. We mock it. Currently just mock a string as we're not doing anything fancy
      global.SpeechSynthesisUtterance = class extends String {};
      global.speechSynthesis = { speak: vi.fn() };
      // mock state
      const state = defaultState();
      state.plates = { 1: plateWithoutPicks({ id: 1 }) };
      const new_plate = pendingScannedPlate({ id: 1 });
      // apply mutation
      updatePlate(state, new_plate);
      // assert result
      expect(state.plates).toEqual({ 1: plateWithoutPicks({ id: 1, scanned: true }) });
    });
  });

  describe("updatePick", () => {
    it("registers a pick if none exists", () => {
      // mock state
      const state = defaultState();
      const new_pick = pick1({ id: 1 });
      // apply mutation
      updatePick(state, new_pick);
      // assert result
      expect(state.picks).toEqual({ 1: new_pick });
    });

    it("updates picks when they exist already", () => {
      // Provided by the browser. We mock it. Currently just mock a string as we're not doing anything fancy
      global.SpeechSynthesisUtterance = class extends String {};
      global.speechSynthesis = { speak: vi.fn() };
      // mock state
      const state = {
        ...defaultState(),
        picks: { 1: pick1({ id: 1, name: "Basket 1", plates: [{ id: 1 }] }) },
      };
      const new_pick = pick1({ id: 1, name: "Basket A" });
      // apply mutation
      updatePick(state, new_pick);
      // assert result
      expect(state.picks).toEqual({ 1: pick1({ id: 1, name: "Basket A", plates: [{ id: 1 }] }) });
    });
  });

  describe("addPickToPlate", () => {
    it("adds a pick to the matching plate", () => {
      const plate = plateWithoutPicks({ id: 1 });
      const state = defaultState();
      state.plates = { 1: plate };
      addPickToPlate(state, { plate: plate, batch: "1", pick: { id: 1 } });
      expect(state.plates[1]).toEqual(plateWithoutPicks({ id: 1, picks: { 1: [{ id: 1 }] } }));
    });

    it("handles picks from other batches", () => {
      const plate = { id: 1, barcode: "DN12345", batches: ["1", "2", "3"], picks: { 1: ["Pick"], 2: ["Other"] } };
      const state = defaultState();
      state.plates = { 1: plate };
      addPickToPlate(state, { plate: plate, batch: "2", pick: "New" });
      expect(state.plates).toEqual({
        1: { id: 1, barcode: "DN12345", batches: ["1", "2", "3"], picks: { 1: ["Pick"], 2: ["Other", "New"] } },
      });
    });

    it("handles previously unseen plates", () => {
      const plate = { id: 1, barcode: "DN12345", batches: ["1", "2", "3"], picks: { 1: ["Pick"], 2: ["Other"] } };
      const state = defaultState();
      addPickToPlate(state, { plate: plate, batch: "2", pick: "New" });
      expect(state.plates).toEqual({
        1: {
          id: 1,
          barcode: "DN12345",
          batches: ["1", "2", "3"],
          picks: { 1: ["Pick"], 2: ["Other", "New"] },
        },
      });
    });
  });

  describe("incrementPick", () => {
    it("keeps track of picks", () => {
      const state = defaultState();
      incrementPick(state);
      expect(state.pickCount).toEqual(1);
    });
  });

  describe("scanPlate", () => {
    it("records each plate with the order in which it was scanned", () => {
      // mock state
      const known_plate = { barcode: "DN12346", id: 1 };
      const state = { ...defaultState(), plates: { 1: known_plate } };
      const new_plate = { barcode: "DN12345" };
      // apply mutation
      scanPlate(state, new_plate);
      scanPlate(state, { barcode: known_plate.barcode });
      expect(state.scanStore).toEqual({
        _DN12345: { barcode: "DN12345", id: null, errorMessage: null },
        _DN12346: { barcode: "DN12346", id: 1, errorMessage: null },
      });
    });

    it("updates the scanned state on existing plates", () => {
      // mock state
      const known_plate = { barcode: "DN12346", id: 1 };
      const plates = { 1: known_plate };
      const state = { ...defaultState(), plates };
      // apply mutation
      scanPlate(state, { barcode: known_plate.barcode });
      expect(state.plates[1].scanned).toEqual(true);
    });
  });

  describe("updateScanPlate", () => {
    it("adds id information to existing records", () => {
      // mock state
      const scanStore = {
        _DN12345R: { barcode: "DN12345R", id: null, errorMessage: null },
      };
      const state = { ...defaultState(), scanStore };
      const new_plate = plateWithoutPicks({ id: 1 });
      // apply mutation
      updateScanPlate(state, new_plate);
      expect(state.scanStore).toEqual({
        _DN12345R: { barcode: "DN12345R", id: 1, errorMessage: null },
      });
    });
    it("adds error information to existing records", () => {
      // mock state
      const scanStore = {
        _DN12345R: { barcode: "DN12345R", id: null, errorMessage: null },
      };
      const state = { ...defaultState(), scanStore };
      // apply mutation
      updateScanPlate(state, { barcode: "DN12345R", errorMessage: "Not found" });
      expect(state.scanStore).toEqual({
        _DN12345R: { barcode: "DN12345R", id: null, errorMessage: "Not found" },
      });
    });
  });

  describe("updateNotifyMode", () => {
    it("sets the notify mode", () => {
      // mock state
      const state = { ...defaultState() };

      // apply mutation
      updateNotifyMode(state, { mode: "long" });
      expect(state.options.notifyMode).toEqual({ mode: "long" });
    });
  });
});
