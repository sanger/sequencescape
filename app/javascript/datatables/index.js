import $ from "jquery";

import "jszip";
import "datatables.net-bs4";
import "datatables.net-buttons-bs4";
import "datatables.net-buttons/js/buttons.colVis.js";
import "datatables.net-buttons/js/buttons.html5.js";
import "datatables.net-fixedcolumns-bs4";
import "datatables.net-fixedheader-bs4";
import "datatables.net-responsive-bs4";
import "datatables.net-rowgroup-bs4";
import "datatables.net-rowreorder-bs4";

// CSS: We need to explicitly import the CSS, as datatables doesn't play great
// with webpacker:
// https://datatables.net/forums/discussion/32542/datatables-and-webpack
import "datatables.net-bs4/css/dataTables.bootstrap4.css";
import "datatables.net-buttons-bs4/css/buttons.bootstrap4.css";
import "datatables.net-rowreorder-bs4/css/rowReorder.bootstrap4.css";
import "datatables.net-fixedheader-bs4/css/fixedHeader.bootstrap4.css";

import { defaults } from "./config";
require("./batch_edit");

$(function () {
  $("table.sortable,table#batch-show").DataTable(defaults);
  // Bit grim. We register the callback with the legacy jQuery
  // until we can migrate everything across.
  window.jQuery(document.body).on("ajaxDomUpdate", function (event, target) {
    $(target).find("table.sortable").DataTable(defaults);
  });
});
