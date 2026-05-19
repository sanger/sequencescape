const startDateInput = document.getElementById("start_date");
const endDateInput = document.getElementById("end_date");
const previewUrl = "/admin/accessioning_tools/bulk_accession_preview";
const previewSpan = document.getElementById("bulk-accession-preview");

function updatePreview() {
  const startDate = startDateInput.value;
  const endDate = endDateInput.value;
  previewSpan.textContent = "loading...";

  const url = `${previewUrl}?start_date=${encodeURIComponent(startDate)}&end_date=${encodeURIComponent(endDate)}`;
  fetch(url, { headers: { Accept: "application/json" } })
    .then((r) => {
      if (!r.ok) throw new Error(`HTTP ${r.status}`);
      return r.json();
    })
    .then((data) => {
      // Only apply the preview if the dates haven't changed since the request was made
      // This prevents a slow response from overwriting a more recent preview
      // submitted-date != current input value
      if (startDate !== startDateInput.value || endDate !== endDateInput.value) {
        console.info("Discarding outdated preview response");
        return;
      }
      previewSpan.textContent = `${data.samples_count} sample(s) over ${data.studies_count} studies`;
    })
    .catch((err) => {
      const code = err.message.startsWith("HTTP ") ? err.message.replace("HTTP ", "") : "unknown";
      previewSpan.textContent = `error occurred (${code})`;
    });
}

startDateInput.addEventListener("change", updatePreview);
endDateInput.addEventListener("change", updatePreview);

document.addEventListener("DOMContentLoaded", updatePreview); // Trigger initial preview on page load
