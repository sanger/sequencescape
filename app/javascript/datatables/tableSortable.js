/*
 * Applies a data-table to any table tagged with the class sortable
 * By default allow for sorting by any column and provides a simple search
 * box for filtering the table.
 * For simple customization options, like enabling pagination, use data-
 * attributes on the table itself. For more advanced customization consider
 * a separate datatables file (see batchEdit.js as an example)
 */

import $ from "jquery";
import { defaults } from "./config";

$(function () {
  $("table.sortable,table#batch-show").DataTable(defaults);
  // Bit grim. We register the callback with the legacy jQuery
  // until we can migrate everything across.
  window.jQuery(document.body).on("ajaxDomUpdate", function (event, target) {
    $(target).find("table.sortable").DataTable(defaults);
  });
});
