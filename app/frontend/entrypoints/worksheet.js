/**
 * Provides just the barcode rendering, useful in worksheets where we don't
 * want to load a lot of javascript
 */
import "../barcodeRendering";

// Automatically trigger print dialog
window.addEventListener("DOMContentLoaded", function () {
  if (document.querySelector("body").dataset.enablePrinting === "true") {
    window.print();
  }
});
