/*
 * Applies a data-table to the batch edit table (batches/:id/edit) with the
 * following features:
 * - Rows are draggable to allow batch re-ordering
 * - A save button submits an AJAX request to update the batch order
 * - Sorting is limited to the position column, to avoid confusion
 */

import $ from "jquery";
import { defaults } from "./config";

const extractIds = (dataTable) =>
  dataTable
    .rows()
    .ids()
    .map((s) => s.replace("request_", ""))
    .toArray();

const saveButton = {
  action: function (e, dt) {
    // this is the button
    this.processing(true);
    const requests_list = extractIds(dt);
    const batch_id = dt.table().node().dataset.batchId;

    // We use jquery for the post here as datatables is already jquery based
    $.post({
      headers: { "X-CSRF-Token": $('meta[name="csrf-token"]').attr("content") },
      url: "/batches/sort",
      data: { batch_id, requests_list },
    })
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
};

$(function () {
  // Batches page, allows re-ordering
  $("table#batch-edit").DataTable({
    ...defaults,
    rowReorder: { selector: "tr" },
    order: [[0, "asc"]],
    columnDefs: [
      { orderable: true, className: "reorder", targets: 0 },
      { orderable: false, targets: "_all" },
    ],
    buttons: [saveButton],
  });
});
