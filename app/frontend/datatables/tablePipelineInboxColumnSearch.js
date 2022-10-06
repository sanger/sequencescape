import $ from "jquery";
import { cssSelectors, defaults } from "./config";

$(document).ready(function () {
  // This function extracts the text contents of the html provided
  function getDisplayedOption(html) {
    let listAnchors = $.parseHTML(html);
    if (listAnchors.length > 0) {
      return listAnchors[0].textContent;
    } else {
      return html;
    }
  }

  // Builds the cell value as an option in the select control
  function addOptionValueToSelect(value, select) {
    let displayedOption = getDisplayedOption(value);
    let option = $("<option></option>");
    option.value = displayedOption;
    option.html(displayedOption);
    select.append(option);
  }

  // Builds a new select in the footer of the column
  function buildSelect(column) {
    var select = $('<select><option value=""> No filter </option></select>')
      .appendTo($(column.footer()).empty())
      .on("change", function () {
        var val = $.fn.dataTable.util.escapeRegex($(this).val());

        column.search(val ? "^" + val + "$" : "", true, false).draw();
      });
    return select;
  }

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

          // Builds a new select control in the footer of the column
          let select = buildSelect(column);

          // Adds the options to the created select control
          column
            .data()
            .unique()
            .sort()
            .each(function (value) {
              addOptionValueToSelect(value, select);
            });
        });
    },
  });
});
