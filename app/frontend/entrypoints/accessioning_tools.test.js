// Tests for accessioning_tools.js live preview behavior

import { describe, it, expect, beforeEach, afterEach, vi, beforeAll } from "vitest";

describe("Accessioning tools preview", () => {
  const initialDate = "2026-05-14";
  let startDateInput;
  let endDateInput;
  let previewSpan;

  const dispatchDomReady = () => {
    document.dispatchEvent(new Event("DOMContentLoaded"));
  };

  const dispatchChange = (el) => {
    el.dispatchEvent(new Event("change", { bubbles: true }));
  };

  beforeAll(async () => {
    document.body.innerHTML = `
      <input id="start_date" type="text" value="${initialDate}" />
      <input id="end_date" type="text" value="${initialDate}" />
      <span id="bulk-accession-preview"></span>
    `;

    global.fetch = vi.fn();

    // Re-import so listeners are registered fresh each test.
    vi.resetModules();
    await import("./accessioning_tools.js");

    startDateInput = document.getElementById("start_date");
    endDateInput = document.getElementById("end_date");
    previewSpan = document.getElementById("bulk-accession-preview");
  });

  beforeEach(() => {
    fetch.mockClear();
    startDateInput.value = initialDate;
    endDateInput.value = initialDate;
    previewSpan.textContent = "";
  });

  afterEach(() => {
    vi.restoreAllMocks();
  });

  it("updates preview text on successful fetch", async () => {
    fetch.mockImplementationOnce(() =>
      Promise.resolve({
        ok: true,
        status: 200,
        json: () => Promise.resolve({ samples_count: 3, studies_count: 1 }),
      }),
    );

    expect(fetch).not.toHaveBeenCalled();
    dispatchDomReady();

    expect(previewSpan.textContent).toBe("loading...");

    await vi.waitFor(() => {
      expect(previewSpan.textContent).toBe("3 sample(s) over 1 studies");
    });

    expect(fetch).toHaveBeenCalledTimes(1);
    expect(fetch.mock.calls[0][0]).toContain("start_date=2026-05-14");
    expect(fetch.mock.calls[0][0]).toContain("end_date=2026-05-14");
    expect(fetch.mock.calls[0][1]).toEqual({
      headers: { Accept: "application/json" },
    });
  });

  it("updates preview when date inputs change", async () => {
    fetch.mockImplementation(() =>
      Promise.resolve({
        ok: true,
        status: 200,
        json: () => Promise.resolve({ samples_count: 5, studies_count: 2 }),
      }),
    );

    expect(fetch).not.toHaveBeenCalled();
    dispatchDomReady();

    startDateInput.value = "2026-05-01";
    dispatchChange(startDateInput);

    await vi.waitFor(() => {
      expect(previewSpan.textContent).toBe("5 sample(s) over 2 studies");
    });

    endDateInput.value = "2026-05-31";
    dispatchChange(endDateInput);

    await vi.waitFor(() => {
      expect(previewSpan.textContent).toBe("5 sample(s) over 2 studies");
    });

    expect(fetch).toHaveBeenCalledTimes(3); // dom-ready + 2 changes
  });

  it("shows error message on fetch failure", async () => {
    fetch.mockImplementation(() =>
      Promise.resolve({
        ok: true,
        status: 200,
        json: () => Promise.reject(new Error("Network error")),
      }),
    );

    expect(fetch).not.toHaveBeenCalled();
    dispatchDomReady();

    expect(previewSpan.textContent).toBe("loading...");

    await vi.waitFor(() => {
      expect(previewSpan.textContent).toBe("error occurred (unknown)");
    });
  });

  it("shows HTTP error code in message when fetch response is not ok", async () => {
    fetch.mockImplementation(() =>
      Promise.resolve({
        ok: false,
        status: 500,
      }),
    );

    expect(fetch).not.toHaveBeenCalled();
    dispatchDomReady();

    expect(previewSpan.textContent).toBe("loading...");

    await vi.waitFor(() => {
      expect(previewSpan.textContent).toBe("error occurred (500)");
    });
  });
});
