import { scannedBarcode, updateCounter } from "@/shared/scanned_barcode";

const $ = window.jQuery;

// Remove polyfill
if (!Element.prototype.remove) {
  Element.prototype.remove = function () {
    this.parentNode.removeChild(this);
  };
}

$(document).ready(function () {
  const counter = document.getElementById("scanned");
  var barcode_list = $("#barcode_list")[0];
  updateCounter(counter, barcode_list);

  $("#barcode_list")
    .find("li")
    .each(function () {
      var removeLink = this.children[1];
      $(removeLink).bind("click", function () {
        this.parentNode.remove();
        updateCounter(counter, barcode_list);
      });
    });

  // On scanning in barcodes, add them to the list.
  $("#asset_scan").bind("blur", function () {
    new scannedBarcode(this, barcode_list, "pooling");
  });

  $("#asset_scan").bind("keydown", function (e) {
    /* We don't take tab index into account here */
    var ENTER = 13,
      TAB = 9,
      code;
    code = e.charCode || e.keyCode;
    if (code == ENTER || code == TAB) {
      e.preventDefault();
      new scannedBarcode(this, barcode_list, "pooling");
      this.focus();
      return false;
    }
  });
});
