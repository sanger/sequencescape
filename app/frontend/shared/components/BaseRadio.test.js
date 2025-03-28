import { shallowMount } from "@vue/test-utils";
import BaseRadio from "./BaseRadio.vue";

describe("BaseRadio.vue", () => {
  it("lists the options", () => {
    const wrapper = shallowMount(BaseRadio, {
      propsData: {
        options: [
          { label: "Option a", value: "a" },
          { label: "Option b", value: "b" },
        ],
        name: "radio",
        id: "radio",
      },
    });

    expect(wrapper.text()).toContain("Option a");
    expect(wrapper.text()).toContain("Option b");
  });
  it("selects the value", () => {
    const wrapper = shallowMount(BaseRadio, {
      propsData: {
        options: [
          { label: "Option a", value: "a" },
          { label: "Option b", value: "b" },
        ],
        name: "radio",
        selected: "a",
        id: "radio",
      },
    });
    expect(wrapper.find("#radio-a").element.checked).toEqual(true);
  });
  it("emits a value when changed", async () => {
    const wrapper = shallowMount(BaseRadio, {
      propsData: {
        options: [
          { label: "Option a", value: "a" },
          { label: "Option b", value: "b" },
        ],
        name: "radio",
        id: "radio",
        selected: "a",
      },
    });

    await wrapper.find("#radio-b").setChecked();

    const events = wrapper.emitted();
    expect(events.change.length).toEqual(1);
    expect(events.change[0]).toEqual(["b"]);
  });
});
