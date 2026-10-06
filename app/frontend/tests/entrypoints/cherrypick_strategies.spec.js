// Tests for cherrypick_strategies.js buffer input toggle and strategy card highlight logic

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
    await import("@/entrypoints/cherrypick_strategies.js");

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

  it("disables buffer input on page load when checkbox is unchecked", () => {
    document.dispatchEvent(new Event("DOMContentLoaded"));

    expect(bufferInput.disabled).toBe(true);
  });

  it("enables buffer input on page load when checkbox is already checked", () => {
    autoBufferCheckbox.checked = true;
    document.dispatchEvent(new Event("DOMContentLoaded"));

    expect(bufferInput.disabled).toBe(false);
  });
});

describe("Strategy card highlight", () => {
  beforeEach(async () => {
    // Mirrors _cherrypick_strategies.html.erb, where the concentration strategy is selected and highlighted by default.
    document.body.innerHTML = `
      <div class="card border-primary" data-group="cherrypick_strategy">
        <h5 class="card-title">Concentration</h5>
        <input type="radio" name="cherrypick[strategy]" value="nano_grams_per_micro_litre" checked />
      </div>
      <div class="card" data-group="cherrypick_strategy">
        <h5 class="card-title">Amount</h5>
        <input type="radio" name="cherrypick[strategy]" value="nano_grams" />
      </div>
      <div class="card" data-group="cherrypick_strategy">
        <h5 class="card-title">Volume</h5>
        <input type="radio" name="cherrypick[strategy]" value="micro_litre" />
      </div>
    `;

    // The radio button listeners are attached on import, so import after the DOM is set up.
    vi.resetModules();
    await import("@/entrypoints/cherrypick_strategies.js");
  });

  const selectStrategy = (strategy) => {
    document.querySelector(`input[name="cherrypick[strategy]"][value="${strategy}"]`).click();
  };

  const highlightedCardTitles = () =>
    [...document.querySelectorAll(".card.border-primary")].map((card) => card.querySelector(".card-title").textContent);

  it.each([
    { strategy: "nano_grams", title: "Amount" },
    { strategy: "micro_litre", title: "Volume" },
  ])("highlights only the $title card when $strategy is selected", ({ strategy, title }) => {
    selectStrategy(strategy);

    expect(highlightedCardTitles()).toEqual([title]);
  });

  it("moves the highlight back to the Concentration card when nano_grams_per_micro_litre is reselected", () => {
    selectStrategy("micro_litre");
    selectStrategy("nano_grams_per_micro_litre");

    expect(highlightedCardTitles()).toEqual(["Concentration"]);
  });
});
