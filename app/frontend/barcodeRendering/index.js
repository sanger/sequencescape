/**
 * Renders barcodes in place of any svg element with the class 'barcode'
 * Uses data-attributes to assist with rendering:
 * data-format = the barcode format
 * data-value = the value of the barcode
 */

import JsBarcode from "jsbarcode";
JsBarcode("svg.barcode").init();
