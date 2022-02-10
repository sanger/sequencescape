var scannedBarcode, updateCounter;

scannedBarcode = function (barcode_source, list, model) {
  var barcode, new_item;
  barcode = barcode_source.value.trim();
  if (barcode != "") {
    this.barcode = barcode;
    this.list = list;
    this.model = model;
    if (this.notInList()) {
      this.createDomElement();
    }
    updateCounter(counter, this.list);
    barcode_source.value = "";
  } else {
    // We're blank or just whitespace.
  }
  barcode_source.value = "";
};

scannedBarcode.prototype = {
  destroy: function () {
    this.domElement.remove();
    updateCounter(counter, this.list);
  },
  notInList: function () {
    var li_items = this.list.getElementsByTagName("li");
    for (var i = 0; i < li_items.length; ++i) {
      if (this.barcode == li_items[i].firstChild.textContent.trim()) {
        return false;
      }
    }
    return true;
  },
  createDomElement: function () {
    var removeLink, scanned_barcode, hiddenField;
    scanned_barcode = this;
    this.domElement = document.createElement("li");
    this.domElement.appendChild(document.createTextNode(this.barcode));

    removeLink = document.createElement("a");
    removeLink.appendChild(document.createTextNode("Remove from list"));
    $(removeLink).bind("click", function () {
      scanned_barcode.destroy();
    });

    hiddenField = document.createElement("input");
    hiddenField.setAttribute("type", "hidden");
    hiddenField.setAttribute("name", this.model + "[barcodes][]");
    hiddenField.setAttribute("value", this.barcode);
    this.domElement.appendChild(hiddenField);

    this.domElement.appendChild(removeLink);
    this.list.appendChild(this.domElement);
  },
  domElement: null,
};

var counter = document.getElementById("scanned");

updateCounter = function (counter, list) {
  counter.innerText = "Scanned: " + list.getElementsByTagName("li").length;
};
