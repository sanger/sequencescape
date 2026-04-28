// Tests for cherrypick_strategies.js buffer input toggle logic

import { describe, it, expect, beforeEach, vi } from "vitest";

describe("Buffer input toggle", () => {
  let bufferInput, autoBufferCheckbox;

  beforeEach(async () => {
    document.body.innerHTML = `
      <input id="buffer_volume_for_empty_wells" type="number" />
      <input id="automatic_buffer_addition" type="checkbox" />
    `;

    // Re-import module so its DOMContentLoaded listener is re-registered each test.
    vi.resetModules();
    await import("./cherrypick_strategies.js");

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
