/*====================================================================
 *  Author: Tony Cox (avc@sanger.ac.uk)
 *  Copyright (c) 2009: Genome Research Ltd.
 * This is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 * or see the on-line version at http://www.gnu.org/copyleft/gpl.txt
 *====================================================================
 * (c) Tony Cox (Sanger Institute, UK) avc@sanger.ac.uk
 *
 * Description: Provides interface for monitoring data in the Sanger
 * Illumina production pipeline
 *
 * Exported functions: None
 * HISTORY:
 *====================================================================
 */

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

function highlightField(state, field) {
  field.style.transition = "background-color 0.25s, color 0.25s";
  // Remove any previous Bootstrap validation classes and inline styles
  field.classList.remove("is-valid", "is-invalid", "bg-success", "bg-danger", "text-white");

  if (state === "good") {
    field.classList.add("is-valid", "bg-success", "text-white");
  } else if (state === "bad") {
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
  // "commonName": "human"
  // }
  return fetch(`/taxa?term=${encodeURIComponent(name)}`, {
    headers: { Accept: "application/json" },
  })
    .then((response) => (response.ok ? response.json() : null))
    .catch(() => null);
}

function fetchTaxonById(id) {
  // expected result:
  // {
  // "taxId": "9606",
  // "scientificName": "Homo sapiens",
  // "commonName": "human"
  // }
  return fetch(`/taxa/${encodeURIComponent(id)}`, {
    headers: { Accept: "application/json" },
  })
    .then((response) => (response.ok ? response.json() : null))
    .catch(() => null);
}

function validateOrganism(commonNameField, taxonIdField) {
  const inputName = commonNameField.value;
  if (!inputName) return;

  fetchTaxonByName(inputName).then(function (taxon) {
    if (!taxon || !taxon.taxId) {
      highlightField("bad", commonNameField);
      highlightField("bad", taxonIdField);
      return;
    }
    fetchTaxonById(taxon.taxId).then(function (taxonDetails) {
      if (!taxonDetails || !taxonDetails.scientificName) {
        highlightField("bad", commonNameField);
        highlightField("bad", taxonIdField);
        return;
      }
      if (commonNameField.value !== taxonDetails.scientificName) {
        commonNameField.value = taxonDetails.scientificName;
        highlightField("good", commonNameField);
      }
      if (taxonIdField.value !== taxon.taxId) {
        taxonIdField.value = taxon.taxId;
        highlightField("good", taxonIdField);
      }
    });
  });
}
