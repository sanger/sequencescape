// Add JavaScript to enable/disable the volume and concentration checkboxes based on the state of the override-samples checkbox
document.addEventListener("DOMContentLoaded", function () {
  const overrideSamples = document.getElementById("override_samples");
  const overwriteVolume = document.getElementById("overwrite_volume");
  const overwriteConcentration = document.getElementById("overwrite_concentration");

  // Enable the vol and conc checkboxes when override-samples is checked, otherwise disable them
  function updateCheckboxStates() {
    overwriteVolume.disabled = !overrideSamples.checked;
    overwriteConcentration.disabled = !overrideSamples.checked;
  }

  // Listen for changes
  overrideSamples.addEventListener("change", updateCheckboxStates);
});
