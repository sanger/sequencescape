const previewUrl = "<%= bulk_accession_preview_admin_accessioning_tools_path %>";
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
