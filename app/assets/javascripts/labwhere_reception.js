//This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
//Please refer to the LICENSE and README files for information on licensing and authorship of this file.
//Copyright (C) 2015,2016 Genome Research Ltd.

(function(window,$,undefined) {
  'use strict';

  // Trim polyfill courtesy of MDN (https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/String/trim)
  // That said, support is pretty much universal, its only IE8 that might cause issues.
  if (!String.prototype.trim) {
    String.prototype.trim = function () {
      return this.replace(/^[\s\uFEFF\xA0]+|[\s\uFEFF\xA0]+$/g, '');
    };
  }

  // Remove polyfill
  if (!Element.prototype.remove) {
    Element.prototype.remove = function() { this.parentNode.removeChild(this); };

  }

  $( document ).ready(function() {

    var barcode_list = $('#barcode_list')[0]

    // The swipecard scanners send a return.
    // This stops it from submitting the form.
    $('#labwhere_reception_user_code').bind("keydown", function(e) {
      /* We don't take tab index into account here */
      var ENTER = 13, TAB = 9, code;
      code=e.charCode || e.keyCode;
      if (code==ENTER || code==TAB) {
        e.preventDefault();
        $('#asset_scan').focus();
        return false;
      }
    });

    // Update the query string automatically on changing the location field
    // Allows the user to bookmark a particular location
    $( '#labwhere_reception_location_id' ).bind('change', function() {
      history.replaceState({}, document.title, '?location_id=' + this.value)
    });

    // On scanning in barcodes, add them to the list.
    $('#asset_scan').bind('blur',function() {
      new scannedBarcode(this,barcode_list, 'labwhere_reception');
    });

    $('#asset_scan').bind("keydown", function(e) {
      /* We don't take tab index into account here */
      var ENTER = 13, TAB = 9, code;
      code=e.charCode || e.keyCode;
      if (code==ENTER || code==TAB) {
        e.preventDefault();
        new scannedBarcode(this,barcode_list, 'labwhere_reception');
        this.focus();
        return false;
      }
    });

  });

})(window,jQuery)
