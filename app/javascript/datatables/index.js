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

// default for bootstrap with added buttons
const dom =
  "<'row'<'col-sm-12 col-md-6'l><'col-sm-12 col-md-6'f>><'row'<'col-sm-12'tr>><'row'<'col-sm-12 col-md-5'i><'col-sm-12 col-md-7'pB>>";

const defaults = { paging: false, order: [], buttons: [], dom, fixedHeader: true };

$(function () {
  $("table.sortable,table#batch-show").DataTable(defaults);

  $.ajaxSetup({
    headers: {
      "X-CSRF-Token": $('meta[name="csrf-token"]').attr("content"),
    },
  });

  // Batches page, allows re-ordering
  $("table#batch-edit").DataTable({
    ...defaults,
    rowReorder: { selector: "tr" },
    order: [[0, "asc"]],
    columnDefs: [
      { orderable: true, className: "reorder", targets: 0 },
      { orderable: false, targets: "_all" },
    ],
    buttons: [
      {
        action: function (e, dt) {
          // this is the button
          this.processing(true);
          const requests_list = dt
            .rows()
            .ids()
            .map((s) => s.replace("request_", ""))
            .toArray();

          const { batchId } = dt.table().node().dataset;
          // We use jquery for the post here as datatables is already jquery based
          $.post(`/batches/sort?batch_id=${batchId}`, { requests_list })
            .fail((_, text) => {
              this.processing(false);
              dt.buttons.info("Failed", `Batch update failed. ${text}`, 3000);
            })
            .done(() => {
              this.processing(false);
              dt.buttons.info("Updated", "Batch updated", 1000);
            });
        },
        text: "Save",
      },
    ],
  });

  // Bit grim. We register the callback with the legacy jQuery
  // until we can migrate everything across.
  window.jQuery(document.body).on("ajaxDomUpdate", function (event, target) {
    $(target).find("table.sortable").DataTable(defaults);
  });
});
