const $ = window.jQuery;

const asset_qc_state = document.getElementById("qc_state_value").value;
const external_release = document.getElementById("external_release_value").value === "true";

$("input[type=checkbox]").each(function (i, checkbox) {
  var field = document.getElementById(checkbox.dataset.field);
  field.disabled = true;

  $(checkbox).on("click", function () {
    const checkbox_status = this.checked;

    if (
      (asset_qc_state == "passed" && !checkbox_status && external_release) ||
      (asset_qc_state == "failed" && checkbox_status && !external_release)
    ) {
      field.disabled = false;
    } else {
      field.disabled = true;
      field[0].selected = true;
    }
  });
});
