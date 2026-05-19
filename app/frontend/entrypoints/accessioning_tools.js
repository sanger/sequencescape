const previewUrl = "/admin/accessioning_tools/bulk_accession_preview";
const previewSpan = document.getElementById("bulk-accession-preview");

function updatePreview() {
  const startDate = document.getElementById("start_date").value;
  const endDate = document.getElementById("end_date").value;
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
      if (
        // submitted-date != current input value
        startDate !== document.getElementById("start_date").value ||
        endDate !== document.getElementById("end_date").value
      ) {
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

document.getElementById("start_date").addEventListener("change", updatePreview);
document.getElementById("end_date").addEventListener("change", updatePreview);

document.addEventListener("DOMContentLoaded", updatePreview); // Trigger initial preview on page load
