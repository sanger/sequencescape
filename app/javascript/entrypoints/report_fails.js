// Copied from from labware_reception.js since similar functionality is required
import { scannedBarcode } from "@/shared/scanned_barcode";

(function (window, $, undefined) {
  "use strict";

  // Trim polyfill courtesy of MDN (https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/trim)
  // That said, support is pretty much universal, its only IE8 that might cause issues.
  if (!String.prototype.trim) {
    String.prototype.trim = function () {
      return this.replace(/^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$/g, "");
    };
  }

  // Remove polyfill
  if (!Element.prototype.remove) {
    Element.prototype.remove = function () {
      this.parentNode.removeChild(this);
    };
  }

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
})(window, jQuery);
