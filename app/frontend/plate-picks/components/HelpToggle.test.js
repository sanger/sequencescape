import { shallowMount } from "@vue/test-utils";
import HelpToggle from "./HelpToggle.vue";

describe("HelpToggle.vue", () => {
  it("renders a help button", () => {
    const wrapper = shallowMount(HelpToggle);
    const button = wrapper.find("button");
    expect(button.text()).toMatch("Show help");
  });

  it("updates the help button when clicked", async () => {
    const wrapper = shallowMount(HelpToggle);
    const button = wrapper.find("button");
    await button.trigger("click");
    expect(button.text()).toMatch("Hide help");
  });

  it("hides help at first", () => {
    const wrapper = shallowMount(HelpToggle);
    expect(wrapper.find("article").element).not.toBeTruthy();
  });

  it("shows help when the button is clicked", async () => {
    const wrapper = shallowMount(HelpToggle);
    const button = wrapper.find("button");
    await button.trigger("click");
    expect(wrapper.find("article").element).toBeTruthy();
  });

  it("hides help when the button is clicked again", async () => {
    const wrapper = shallowMount(HelpToggle);
    const button = wrapper.find("button");
    await button.trigger("click");
    await button.trigger("click");
    expect(wrapper.find("article").element).not.toBeTruthy();
  });
});
