const startDateInput = document.getElementById("start_date");
const endDateInput = document.getElementById("end_date");
const viewSampleNamesInput = document.getElementById("view_sample_names");
const viewAccessionNumbersTableBody = document
  .getElementById("sample_accession_numbers_table")
  .getElementsByTagName("tbody")[0];
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

function clearTable(tableBodyElement) {
  while (tableBodyElement.firstChild) {
    tableBodyElement.removeChild(tableBodyElement.firstChild);
  }
}

function insertLinkRow(tableBodyElement, contents, urls) {
  const row = tableBodyElement.insertRow();
  // Insert cells with links for each content and corresponding URL
  contents.forEach((content, index) => {
    const cell = row.insertCell();
    if (urls[index]) {
      const link = document.createElement("a");
      link.href = urls[index];
      link.textContent = content || "\u00A0"; // Use nbsp; for empty cells to maintain table spacing
      cell.appendChild(link);
    } else {
      cell.textContent = content || "\u00A0"; // Use nbsp; for empty cells to maintain table spacing
    }
  });
}

/*
Get the list of accession numbers for the given samples names.
- Get the list of sample names from the textarea
- Clean them up, maintaining the line order and breaks
- Send to the server via a PUT request (due to get length limits)
- Display the returned sample names and accession numbers in the table, maintaining the line order
*/
function view_sample_accessions() {
  const sampleNames = viewSampleNamesInput.value
    .replaceAll(",", "")
    .split("\n")
    .map((name) => name.trim());
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
      // Clear the table body before populating it with new data
      clearTable(viewAccessionNumbersTableBody);

      // Populate the table with the returned sample names and accession numbers
      data.sample_names.forEach((sampleName, index) => {
        const samplePath = data.sample_paths[index];
        const accessionNumber = data.accession_numbers[index];
        insertLinkRow(viewAccessionNumbersTableBody, [sampleName, accessionNumber], [samplePath, null]);
      });
    })
    .catch((err) => {
      const code = err.message.startsWith("HTTP ") ? err.message.replace("HTTP ", "") : "unknown";

      // Clear the table body and display an error message in a single row
      clearTable(viewAccessionNumbersTableBody);
      insertRow(viewAccessionNumbersTableBody, [`Error occurred (${code})`, ""]);
    });
}

startDateInput.addEventListener("change", updatePreview);
endDateInput.addEventListener("change", updatePreview);
viewSampleAccessionNumbersButton.addEventListener("click", view_sample_accessions);

document.addEventListener("DOMContentLoaded", updatePreview); // Trigger initial preview on page load
