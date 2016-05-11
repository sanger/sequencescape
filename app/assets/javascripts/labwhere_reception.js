//This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
//Please refer to the LICENSE and README files for information on licensing and authorship of this file.
//Copyright (C) 2015,2016 Genome Research Ltd.

(function(window,$,undefined) {
  'use strict';

  var scannedBarcode, updateCounter;

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

  scannedBarcode = function(barcode_source,list) {
    var barcode, new_item;
      barcode = barcode_source.value.trim();
      if (barcode != "") {
        this.barcode = barcode;
        this.list    = list;
        if (this.notInList()) {this.createDomElement()};
        updateCounter(counter, this.list);
        barcode_source.value = "";
      } else {
        // We're blank or just whitespace.
      }
    barcode_source.value = "";
  }

  scannedBarcode.prototype = {
    destroy: function() {
      this.domElement.remove();
      updateCounter(counter, this.list);
    },
    notInList: function(){
      var li_items = this.list.getElementsByTagName('li')
      for (var i=0; i<li_items.length; ++i){
        if (this.barcode == li_items[i].firstChild.textContent) {
          return false
        }
      }
      return true
    },
    createDomElement: function() {
      var removeLink, scanned_barcode, hiddenField;
      scanned_barcode = this;
      this.domElement = document.createElement('li');
      this.domElement.appendChild(document.createTextNode(this.barcode));

      removeLink = document.createElement('a')
      removeLink.appendChild(document.createTextNode('Remove from list'));
      $(removeLink).bind('click',function() { scanned_barcode.destroy(); })

      hiddenField = document.createElement('input');
      hiddenField.setAttribute('type','hidden');
      hiddenField.setAttribute('name','labwhere_reception[barcodes]['+this.barcode+']')
      hiddenField.setAttribute('value',this.barcode)
      this.domElement.appendChild(hiddenField);

      this.domElement.appendChild(removeLink);
      this.list.appendChild(this.domElement);
    },
    domElement: null
  }

  var counter = document.getElementById('scanned')

  updateCounter = function(counter, list){
    counter.innerText = "Scanned: " + list.getElementsByTagName('li').length
  }

  $( document ).ready(function() {

    var barcode_list = $('#barcode_list')[0]

    // Update the query string automatically on changing the location field
    // Allows the user to bookmark a particular location
    $( '#labwhere_reception_location_id' ).bind('change', function() {
      history.replaceState({}, document.title, '?location_id=' + this.value)
    });

    // On scanning in barcodes, add them to the list.
    $('#asset_scan').bind('blur',function() {
      new scannedBarcode(this,barcode_list);
    });

    $('#asset_scan').bind("keydown", function(e) {
      /* We don't take tab index into account here */
      var ENTER = 13, TAB = 9, code;
      code=e.charCode || e.keyCode;
      if (code==ENTER || code==TAB) {
        e.preventDefault();
        new scannedBarcode(this,barcode_list);
        this.focus();
        return false;
      }
    });

  });

})(window,jQuery)
