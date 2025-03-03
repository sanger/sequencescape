import { shallowMount } from "@vue/test-utils";
import PicksSection from "./PicksSection.vue";
import PicksSectionBatch from "./PicksSectionBatch.vue";
import defaultState from "../store/state";

describe("PicksSection.vue", () => {
  it("provides feedback when no picks are visible", () => {
    const wrapper = shallowMount(PicksSection, {
      mocks: {
        $store: {
          state: defaultState(),
          getters: { denormalizedBatches: [] },
        },
      },
    });
    expect(wrapper.text()).toContain("Start scanning plates to see the associated picks");
  });

  it("renders a list of batches when visible", () => {
    const wrapper = shallowMount(PicksSection, {
      mocks: {
        $store: {
          state: {
            ...defaultState,
            batches: {
              1: {
                id: "1",
                picks: [
                  {
                    name: "Name 1",
                    plates: [
                      { barcode: "DN12345R", batches: ["1"] },
                      { barcode: "DN12346S", batches: ["1"] },
                    ],
                  },
                  {
                    name: "Name 2",
                    plates: [
                      { barcode: "DN12347T", batches: ["1"] },
                      { barcode: "DN12348U", batches: ["1", "2"] },
                    ],
                  },
                ],
              },
              2: {
                id: "2",
                picks: [
                  {
                    name: "Name 3",
                    plates: [{ barcode: "DN12348U", batches: ["1", "2"] }],
                  },
                ],
              },
            },
          },
          getters: {
            denormalizedBatches: [
              {
                id: "1",
                picks: [
                  {
                    name: "Name 1",
                    plates: [
                      { barcode: "DN12345R", batches: ["1"] },
                      { barcode: "DN12346S", batches: ["1"] },
                    ],
                  },
                  {
                    name: "Name 2",
                    plates: [
                      { barcode: "DN12347T", batches: ["1"] },
                      { barcode: "DN12348U", batches: ["1", "2"] },
                    ],
                  },
                ],
              },
              {
                id: "2",
                picks: [
                  {
                    name: "Name 3",
                    plates: [{ barcode: "DN12348U", batches: ["1", "2"] }],
                  },
                ],
              },
            ],
          },
        },
      },
    });
    const batches = wrapper.findAllComponents(PicksSectionBatch);
    expect(batches.length).toBe(2);
    expect(batches.at(0).props("id")).toBe("1");
    expect(batches.at(1).props("id")).toBe("2");
  });
});
