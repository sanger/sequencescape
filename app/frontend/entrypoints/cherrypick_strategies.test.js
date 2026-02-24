// cherrypick_strategies.test.js
// Tests for cherrypick_strategies.js buffer input toggle logic

/**
 * @jest-environment jsdom
 */

describe('Buffer input toggle', () => {
  let bufferInput, autoBufferCheckbox;

  beforeEach(() => {
    document.body.innerHTML = `
      <input id="buffer_volume_for_empty_wells" type="number" />
      <input id="automatic_buffer_addition" type="checkbox" />
    `;
    // Re-require the script to attach event listeners
    jest.resetModules();
    require('./cherrypick_strategies.js');
    bufferInput = document.getElementById('buffer_volume_for_empty_wells');
    autoBufferCheckbox = document.getElementById('automatic_buffer_addition');
  });

  it('disables buffer input when checkbox is unchecked', () => {
    autoBufferCheckbox.checked = false;
    document.dispatchEvent(new Event('DOMContentLoaded'));
    expect(bufferInput.disabled).toBe(true);
  });

  it('enables buffer input when checkbox is checked', () => {
    autoBufferCheckbox.checked = true;
    document.dispatchEvent(new Event('DOMContentLoaded'));
    expect(bufferInput.disabled).toBe(false);
  });
});
