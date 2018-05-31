(function($, undefined) {

  var TABLE_SORTER_CONFIG = {

    // third click on the header will reset column to default - unsorted
    sortReset   : true,
    // Resets the sort direction so that clicking on an unsorted column will sort in the sortInitialOrder direction.
    sortRestart : true,

    // this will apply the bootstrap theme if "uitheme" widget is included
    // the widgetOptions.uitheme is no longer required to be set
    theme : "bootstrap",

    //widthFixed: true,

    headerTemplate : '{content} {icon}', // new in v2.7. Needed to add the bootstrap icon!

    // widget code contained in the jquery.tablesorter.widgets.js file
    // use the zebra stripe widget if you plan on hiding any rows (filter widget)
    widgets : [ "uitheme", "zebra" ],

    widgetOptions : {
      // using the default zebra striping class name, so it actually isn't included in the theme variable above
      // this is ONLY needed for bootstrap theming if you are using the filter widget, because rows are hidden
      zebra : ["even", "odd"],

      // reset filters button
      //filter_reset : ".reset",

      // extra css class name (string or array) added to the filter element (input or select)
      //filter_cssFilter: "form-control",

      // if true, filters are collapsed initially, but can be revealed by hovering over the grey bar immediately
      // below the header row. Additionally, tabbing through the document will open the filter row when an input gets focus
      //filter_hideFilters : true
    }

      // set the uitheme widget to use the bootstrap theme class names
      // this is no longer required, if theme is set
      // ,uitheme : "bootstrap"
  };

  var TABLE_SORTER_PAGER_CONFIG = {
    // target the pager markup - see the HTML block below
    container: $(".ts-pager"),

    // target the pager page select dropdown - choose a page
    cssGoto  : ".pagenum",

    // remove rows from the table to speed up the sort of large tables.
    // setting this to false, only hides the non-visible rows; needed if you plan to add/remove rows with the pager enabled.
    removeRows: false,

    // output string - default is '{page}/{totalPages}';
    // possible variables: {page}, {totalPages}, {filteredPages}, {startRow}, {endRow}, {filteredRows} and {totalRows}
    output: '{startRow} - {endRow} / {filteredRows} ({totalRows})'
  };

  var attachEvents;

  $.tablesorter.themes.bootstrap.table = 'table table-striped';

  attachEvents = function() {
    $(document.body).on("ajaxDomUpdate", function() {
      var tables = $("table.sortable");
      tables.tablesorter(TABLE_SORTER_CONFIG);
      tables.trigger("sortReset");
    });
    $(document.body).trigger("ajaxDomUpdate");
  };
  $(document).ready(attachEvents);

})(jQuery);
