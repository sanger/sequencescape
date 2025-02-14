import { shallowMount } from "@vue/test-utils";
import PlatesSection from "./PlatesSection.vue";
import PlatesSectionPlate from "./PlatesSectionPlate.vue";
import defaultState from "../store/state";

describe("PlatesSection.vue", () => {
  it("renders a list of scanned plates", () => {
    const allPlates = {
      1: { barcode: "DN12345R", scanned: true, status: "Pick", picks: { 1: { name: "Example Pick 1 of 3" } } },
      2: { barcode: "DN12346S", scanned: true, status: "Pick", picks: { 1: { name: "Example Pick 1 of 3" } } },
      3: { barcode: "DN12347T", status: "Pick", picks: { 1: { name: "Example Pick 1 of 3" } } },
    };
    const wrapper = shallowMount(PlatesSection, {
      mocks: {
        $store: {
          state: {
            ...defaultState(),
            plates: allPlates,
          },
          getters: {
            scannedPlates: Object.values(allPlates).filter((plate) => plate.scanned),
          },
        },
      },
    });
    const plates = wrapper.findAllComponents(PlatesSectionPlate);
    expect(plates.length).toBe(2);
    expect(plates.at(0).props("barcode")).toBe("DN12345R");
    expect(plates.at(1).props("barcode")).toBe("DN12346S");
  });

  it("triggers plate lookup", async () => {
    const mockStore = {
      state: defaultState(),
      dispatch: vi.fn(),
      getters: { sortedScannedPlates: [] },
    };
    const wrapper = shallowMount(PlatesSection, {
      mocks: {
        $store: mockStore,
      },
    });

    const input = wrapper.find("#scan-plate");
    await input.setValue("DN12345R");
    await input.trigger("keydown.enter");

    expect(mockStore.dispatch).toHaveBeenCalledWith("plateBarcodeScan", "DN12345R");
  });

  it("ignores empty input", async () => {
    const mockStore = {
      state: defaultState(),
      dispatch: vi.fn(),
      getters: { sortedScannedPlates: [] },
    };
    const wrapper = shallowMount(PlatesSection, {
      mocks: {
        $store: mockStore,
      },
    });

    const input = wrapper.find("#scan-plate");
    await input.setValue("   ");
    await input.trigger("blur");

    expect(mockStore.dispatch).not.toHaveBeenCalled();
  });
});
