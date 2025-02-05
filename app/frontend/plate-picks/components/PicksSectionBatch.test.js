import { shallowMount } from "@vue/test-utils";
import PicksSectionBatch from "./PicksSectionBatch.vue";
import PicksSectionBatchPick from "./PicksSectionBatchPick.vue";

describe("PicksSectionBatch.vue", () => {
  it("shows the batch id", () => {
    const wrapper = shallowMount(PicksSectionBatch, {
      propsData: {
        id: "12345",
      },
    });
    expect(wrapper.text()).toContain("12345");
  });

  it("shows Fetching batch information when loading the batch", () => {
    const wrapper = shallowMount(PicksSectionBatch, {
      propsData: {
        id: "12345",
      },
    });
    expect(wrapper.text()).toContain("Fetching batch information");
  });

  it("shows any errors received", () => {
    const errorMessage = "This batch contains only bananas";
    const wrapper = shallowMount(PicksSectionBatch, {
      propsData: {
        id: "12345",
        errorMessage,
      },
    });
    expect(wrapper.text()).toContain(errorMessage);
  });

  it("renders each pick", () => {
    const wrapper = shallowMount(PicksSectionBatch, {
      propsData: {
        id: "12345",
        picks: [
          {
            name: "Name 1",
            short: "Basket 1",
            id: "1",
            plates: [
              { barcode: "DN12345R", batches: ["1"] },
              { barcode: "DN12346S", batches: ["1"] },
            ],
          },
          {
            name: "Name 2",
            short: "Basket 2",
            id: "2",
            plates: [
              { barcode: "DN12347T", batches: ["1"] },
              { barcode: "DN12348U", batches: ["1", "2"] },
            ],
          },
        ],
      },
    });
    const picks = wrapper.findAllComponents(PicksSectionBatchPick);
    expect(picks.length).toBe(2);
    expect(picks.at(0).props("name")).toBe("Name 1");
    expect(picks.at(1).props("name")).toBe("Name 2");
  });
});
