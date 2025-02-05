import { shallowMount } from "@vue/test-utils";
import PlatesSectionPlate from "./PlatesSectionPlate.vue";
import defaultState from "../store/state";

describe("PlatesSectionPlate.vue", () => {
  it("lists the plate", () => {
    const wrapper = shallowMount(PlatesSectionPlate, {
      mocks: {
        $store: {
          state: { ...defaultState() },
          getters: {},
        },
      },
      propsData: {
        barcode: "DN12345",
      },
    });
    expect(wrapper.text()).toContain("DN12345");
  });

  it("indicates when something went wrong", () => {
    const wrapper = shallowMount(PlatesSectionPlate, {
      mocks: {
        $store: {
          state: { ...defaultState() },
          getters: {},
        },
      },
      propsData: {
        barcode: "DN12345",
        errorMessage: "This is bad",
      },
    });
    expect(wrapper.text()).toContain("DN12345");
    expect(wrapper.text()).toContain("This is bad");
    expect(wrapper.find(".table-danger")).toBeTruthy();
  });

  it("indicates when its looking up a plate", () => {
    const wrapper = shallowMount(PlatesSectionPlate, {
      mocks: {
        $store: {
          state: { ...defaultState() },
          getters: {},
        },
      },
      propsData: {
        barcode: "DN12345",
      },
    });
    expect(wrapper.text()).toContain("Fetching plate information");
    expect(wrapper.find(".table-warning")).toBeTruthy();
  });

  it("indicates when its looking up a batch", () => {
    const wrapper = shallowMount(PlatesSectionPlate, {
      mocks: {
        $store: {
          state: { ...defaultState() },
          getters: {},
        },
      },
      propsData: {
        barcode: "DN12345",
        batches: ["1", "2"],
        picks: { 1: [{ name: "Pick", id: 1 }] },
      },
    });
    expect(wrapper.text()).toContain("Fetching batch information");
    expect(wrapper.find(".table-warning")).toBeTruthy();
  });

  it("indicates when its a control", () => {
    const wrapper = shallowMount(PlatesSectionPlate, {
      mocks: {
        $store: {
          state: { ...defaultState() },
          getters: {},
        },
      },
      propsData: {
        barcode: "DN12345",
        batches: [],
        control: true,
        picks: {},
      },
    });
    expect(wrapper.find(".table-secondary")).toBeTruthy();
    expect(wrapper.text()).toContain("Control");
  });

  it("indicates when its a single pick", () => {
    const wrapper = shallowMount(PlatesSectionPlate, {
      mocks: {
        $store: {
          state: { ...defaultState() },
          getters: {},
        },
      },
      propsData: {
        barcode: "DN12345",
        batches: ["1"],
        picks: { 1: [{ name: "Pick A", id: 1, short: "Basket 1" }] },
      },
    });
    expect(wrapper.find(".table-success")).toBeTruthy();
    expect(wrapper.text()).toContain("Basket 1");
  });

  it("indicates when its a multi pick", () => {
    const wrapper = shallowMount(PlatesSectionPlate, {
      mocks: {
        $store: {
          state: { ...defaultState() },
          getters: {},
        },
      },
      propsData: {
        barcode: "DN12345",
        batches: ["1"],
        picks: {
          1: [
            { name: "Pick A", id: 1, short: "Basket 1" },
            { name: "Pick B", id: 2, short: "Basket 2" },
          ],
        },
      },
    });
    expect(wrapper.find(".table-info")).toBeTruthy();
    expect(wrapper.text()).toContain("Basket 1");
    expect(wrapper.text()).toContain("Basket 2");
  });

  it("uses the full name when option is set", () => {
    const wrapper = shallowMount(PlatesSectionPlate, {
      mocks: {
        $store: {
          state: {
            ...defaultState(),
            options: { notifyMode: { mode: "long" } },
          },
          getters: {},
        },
      },
      propsData: {
        barcode: "DN12345",
        batches: ["1"],
        picks: { 1: [{ name: "Pick A", id: 1, short: "Basket 1" }] },
      },
    });
    expect(wrapper.find(".table-success")).toBeTruthy();
    expect(wrapper.text()).toContain("Pick A");
  });

  it("assigns the pick a class based on id", () => {
    const wrapper = shallowMount(PlatesSectionPlate, {
      mocks: {
        $store: {
          state: { ...defaultState() },
          getters: {},
        },
      },
      propsData: {
        barcode: "DN12345",
        batches: ["1"],
        picks: {
          1: [
            { name: "Pick A", id: 1, short: "Basket 1" },
            { name: "Pick B", id: 2, short: "Basket 2" },
          ],
        },
      },
    });
    expect(wrapper.find(".colour-1")).toBeTruthy();
    expect(wrapper.find(".colour-2")).toBeTruthy();
  });
});
