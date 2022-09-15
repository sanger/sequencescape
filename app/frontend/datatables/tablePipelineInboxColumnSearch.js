import $ from "jquery";
import { cssSelectors, defaults } from "./config";

$(document).ready(function () {
  $(cssSelectors.PipelineInboxConfig).DataTable({
    ...defaults,
    initComplete: function () {
      this.api()
        .columns([2, 3])
        .every(function () {
          var column = this;
          // Dont add the control if there isnt anything to filter
          if (column.data().length == 0) {
            return;
          }
          var select = $('<select><option value=""> No filter </option></select>')
            .appendTo($(column.footer()).empty())
            .on("change", function () {
              var val = $.fn.dataTable.util.escapeRegex($(this).val());

              column.search(val ? "^" + val + "$" : "", true, false).draw();
            });
          column
            .data()
            .unique()
            .sort()
            .each(function (value) {
              if (value.indexOf("<a") >= 0) {
                var indexFrom = value.indexOf(">");
                var indexTo = value.indexOf("<", indexFrom);
                var anchorText = value.substring(indexFrom + 1, indexTo);
                select.append('<option value="' + anchorText + '">' + anchorText + "</option>");
              } else {
                select.append('<option value="' + value + '">' + value + "</option>");
              }
            });
        });
    },
  });
});
