const startDateInput = document.getElementById("start_date");
const endDateInput = document.getElementById("end_date");
const viewSampleNamesInput = document.getElementById("view_sample_names");
const viewAccessionNumbersInput = document.getElementById("view_accession_numbers");
const viewSampleAccessionNumbersButton = document.getElementById("view_sample_accession_numbers_button");

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

/*
Get the list of accession numbers for the given samples names.
- Get the list of sample names from the textarea
- Clean them up, maintaining the line order and breaks
- Send to the server via a PUT request (due to get length limits)
- Display the returned accession numbers in the other textarea
*/
function view_sample_accessions() {
  const sampleNames = viewSampleNamesInput.value.split("\n").map((name) => name.trim());
  const url = "/admin/accessioning_tools/view_sample_accessions";
  const data = { sample_names: sampleNames };

  fetch(url, {
    method: "PUT",
    headers: {
      "Content-Type": "application/json",
      Accept: "application/json",
    },
    body: JSON.stringify(data),
  })
    .then((r) => {
      if (!r.ok) throw new Error(`HTTP ${r.status}`);
      return r.json();
    })
    .then((data) => {
      viewAccessionNumbersInput.value = data.accession_numbers.join("\n");
    })
    .catch((err) => {
      const code = err.message.startsWith("HTTP ") ? err.message.replace("HTTP ", "") : "unknown";
      viewAccessionNumbersInput.value = `error occurred (${code})`;
    });
}

startDateInput.addEventListener("change", updatePreview);
endDateInput.addEventListener("change", updatePreview);
viewSampleAccessionNumbersButton.addEventListener("click", view_sample_accessions);

document.addEventListener("DOMContentLoaded", updatePreview); // Trigger initial preview on page load
