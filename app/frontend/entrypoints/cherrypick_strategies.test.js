// cherrypick_strategies.test.js
// Tests for cherrypick_strategies.js buffer input toggle logic

/* global describe, it, expect, beforeEach, jest */
/* @jest-environment jsdom */

describe("Buffer input toggle", () => {
  let bufferInput, autoBufferCheckbox;

  beforeEach(() => {
    document.body.innerHTML = `
      <input id="buffer_volume_for_empty_wells" type="number" />
      <input id="automatic_buffer_addition" type="checkbox" />
    `;
    // Re-require the script to attach event listeners
    jest.resetModules();
    require("./cherrypick_strategies.js");
    bufferInput = document.getElementById("buffer_volume_for_empty_wells");
    autoBufferCheckbox = document.getElementById("automatic_buffer_addition");
  });

  it("enables and disables buffer input when checkbox is toggled", () => {
    // register the change event handler
    // bufferInput is initially disabled because autoBufferCheckbox is unchecked
    document.dispatchEvent(new Event("DOMContentLoaded"));

    autoBufferCheckbox.click(); // unchecked to checked
    expect(bufferInput.disabled).toBe(false);

    autoBufferCheckbox.click(); // checked to unchecked
    expect(bufferInput.disabled).toBe(true);
  });
});
