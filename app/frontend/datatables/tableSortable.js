/*
 * Applies a data-table to any table tagged with the class sortable
 * By default allow for sorting by any column and provides a simple search
 * box for filtering the table.
 * For simple customization options, like enabling pagination, use data-
 * attributes on the table itself. For more advanced customization consider
 * a separate datatables file (see batchEdit.js as an example)
 */

import $ from "jquery";
import { defaults, cssSelectors } from "./config";

$(function () {
  // Looping through and applying DataTable separately to each.
  // The alternative, $( "table.sortable,table#batch-show" ).DataTable, caused issue
  // on pages that had multiple .sortable tables:
  // the search box was duplicated and pagination settings ignored,
  // and tables with no rows had the following error in the js console:
  // "Uncaught TypeError: Cannot set properties of undefined (setting '_DT_CellIndex')""
  // Looping through like this seems to solve these issues.
  $(cssSelectors.DefaultConfig).each(function (_index) {
    $(this).DataTable(defaults);
  });

  // If we update the DOM via ajax we want to mount the included components
  $(document.body).on("ajaxDomUpdate", function (_event, target) {
    $(target).find(cssSelectors.AjaxConfig).DataTable(defaults);
  });
});
