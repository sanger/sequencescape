/*
 * Applies a data-table to any table tagged with the class sortable
 * By default allow for sorting by any column and provides a simple search
 * box for filtering the table.
 * For simple customization options, like enabling pagination, use data-
 * attributes on the table itself. For more advanced customization consider
 * a separate datatables file (see batchEdit.js as an example)
 */

import $ from "jquery";
import { cssSelectors, defaults } from "./config";
import DataTable from "datatables.net-bs4";

$(function () {
  document.querySelectorAll(cssSelectors.DefaultConfig).forEach((table) => {
    new DataTable(table, { ...defaults, order: [] });
  });

  // If we update the DOM via ajax we want to mount the included components
  $(document.body).on("ajaxDomUpdate", function (_event, target) {
    new DataTable($(target).find(cssSelectors.AjaxConfig), defaults);
  });
});
