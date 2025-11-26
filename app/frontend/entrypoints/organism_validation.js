document.addEventListener("DOMContentLoaded", function () {
  // Attach validation to all .validate_organism controls
  document.querySelectorAll(".validate_organism").forEach(function (button) {
    button.addEventListener("click", function (event) {
      event.preventDefault();
      const commonNames = document.querySelectorAll('input[data-organism="common_name"]');
      const taxonIds = document.querySelectorAll('input[data-organism="taxon_id"]');
      commonNames.forEach(function (commonNameInput, idx) {
        validateOrganism(commonNameInput, taxonIds[idx]);
      });
    });
  });
});

function highlightField(field, state) {
  field.style.transition = "background-color 0.25s, color 0.25s";
  // Remove any previous Bootstrap validation classes and inline styles
  field.classList.remove("is-valid", "is-invalid", "bg-success", "bg-danger", "text-white");

  if (state === "success") {
    field.classList.add("is-valid", "bg-success", "text-white");
  } else if (state === "failure") {
    field.classList.add("is-invalid", "bg-danger", "text-white");
  }

  // Remove highlights and text color after 1.5s
  // Validity classes remain for user reference
  setTimeout(() => {
    field.classList.remove("bg-success", "bg-danger", "text-white");
  }, 1500);
}

function fetchTaxonByName(name) {
  // expected result:
  // {
  // "taxId": "9606",
  // "scientificName": "Homo sapiens",
  // "commonName": "human",
  // "submittable": "true"
  // }
  return fetch(`/taxa?term=${encodeURIComponent(name)}`, {
    headers: { Accept: "application/json" },
  })
    .then((response) => (response.ok ? response.json() : null))
    .catch(() => null);
}

function validateOrganism(commonNameField, taxonIdField) {
  const inputName = commonNameField.value;
  if (!inputName) return;

  fetchTaxonByName(inputName).then(function (taxon) {
    // Handle not found (404 or no result)
    if (!taxon || !taxon.taxId || !taxon.scientificName || !taxon.submittable) {
      highlightField(commonNameField, "failure");
      highlightField(taxonIdField, "failure");
      taxonIdField.value = "<not found>";
      taxonIdField.setCustomValidity("This organism cannot be found.");
      return;
    }

    // Set the name and taxon id fields to the returned values
    commonNameField.value = taxon.scientificName; // yes the field is called common name, yes this is confusing, no I have no idea why we do it this way...
    taxonIdField.value = taxon.taxId;

    // Highlight the fields, indicating if they are submittable
    const submittable = taxon.submittable == "true" ? "success" : "failure";
    highlightField(commonNameField, submittable);
    highlightField(taxonIdField, submittable);

    // If the taxon is not submittable, prevent form submission by setting custom validity
    if (taxon.submittable != "true") {
      commonNameField.setCustomValidity("This organism is not submittable.");
      taxonIdField.setCustomValidity("This organism is not submittable.");
    } else {
      commonNameField.setCustomValidity("");
      taxonIdField.setCustomValidity("");
    }
  });
}
