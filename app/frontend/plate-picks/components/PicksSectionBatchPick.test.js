import { shallowMount } from "@vue/test-utils";
import PicksSectionBatchPick from "./PicksSectionBatchPick.vue";
import defaultState from "../store/state";
import { storePlateWithPicks } from "../_test_examples_";

describe("PicksSectionBatchPick.vue", () => {
  const name = "Pick Name";
  const short = "Basket 1";

  it("includes the name", () => {
    const wrapper = shallowMount(PicksSectionBatchPick, {
      propsData: {
        name,
        short,
        id: "1",
        plates: [],
      },
      mocks: {
        $store: {
          state: defaultState(),
          getters: {},
        },
      },
    });
    expect(wrapper.text()).toContain(name);
  });

  it("includes lists the plates", () => {
    const wrapper = shallowMount(PicksSectionBatchPick, {
      propsData: {
        name,
        short,
        id: "1",
        plates: [storePlateWithPicks({ barcode: "DN12345" })],
      },
      mocks: {
        $store: {
          state: defaultState(),
          getters: {},
        },
      },
    });
    expect(wrapper.text()).toContain("DN12345");
  });

  it("indicates scanned plates", () => {
    const wrapper = shallowMount(PicksSectionBatchPick, {
      propsData: {
        name,
        short,
        id: "1",
        plates: [storePlateWithPicks({ barcode: "DN12345", scanned: true })],
      },
      mocks: {
        $store: {
          state: defaultState(),
          getters: {},
        },
      },
    });
    expect(wrapper.find(".list-group-item-success").text()).toContain("DN12345");
  });

  it("indicates scanned plates", () => {
    const wrapper = shallowMount(PicksSectionBatchPick, {
      propsData: {
        name,
        short,
        id: "1",
        plates: [storePlateWithPicks({ barcode: "DN12345", scanned: false })],
      },
      mocks: {
        $store: {
          state: defaultState(),
          getters: {},
        },
      },
    });
    expect(wrapper.find(".list-group-item-success").exists()).toBe(false);
  });

  it("includes an editable short name", async () => {
    const commit = vi.fn();
    const wrapper = shallowMount(PicksSectionBatchPick, {
      propsData: {
        name,
        short,
        id: "1",
        plates: [],
      },
      mocks: {
        $store: {
          state: defaultState(),
          getters: {},
          commit,
        },
      },
    });

    const input = wrapper.find("input");
    expect(input.element.value).toEqual(short);

    await input.setValue("newName");

    expect(commit).toHaveBeenCalledWith("updatePick", { id: "1", short: "newName" });
  });
});
