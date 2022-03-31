// Copied from from labware_reception.js since similar functionality is required
import { scannedBarcode } from "@/shared/scanned_barcode";
const $ = window.jQuery;

$(document).ready(function () {
  var barcode_list = $("#barcode_list")[0];

  // The swipecard scanners send a return - this stops it from submitting the form.
  $("#report_fail_user_code").bind("keydown", function (e) {
    /* We don't take tab index into account here */
    var ENTER = 13,
      TAB = 9,
      code;
    code = e.charCode || e.keyCode;
    if (code == ENTER || code == TAB) {
      e.preventDefault();
      $("#failed_labware_barcodes").focus();
      return false;
    }
  });

  // On scanning in barcodes, add them to the list.
  $("#asset_scan").bind("blur", function () {
    new scannedBarcode(this, barcode_list, "report_fail");
  });

  $("#asset_scan").bind("keydown", function (e) {
    /* We don't take tab index into account here */
    var ENTER = 13,
      TAB = 9,
      code;
    code = e.charCode || e.keyCode;
    if (code == ENTER || code == TAB) {
      e.preventDefault();
      new scannedBarcode(this, barcode_list, "report_fail");
      this.focus();
      return false;
    }
  });
});
