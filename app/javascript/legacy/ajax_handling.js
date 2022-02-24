// Sets up AJAX functionality for links and forms
// to allow AJAX updating of page elements
//
// Binds to: links with the attribute data-remote=true
//           DOM objects with the class remote-form
//           DOM objects with the class observed will submit every 0.5s if data
//           changes
//
// Will use the following data attributes
// data-throbber: A JQuery identifier (eg. #id or .class) for the DOM element
//                representing an in progress spinner to show/hide as a query
//                runs
// data-success: A JQuery identifier (eg. #id or .class) for the DOM element to
//               update with the payload in the event of a success
// data-failure: A JQuery identifier (eg. #id or .class) for the DOM element to
//               update with the payload in the event of a failure
// data-update:  A JQuery identifier (eg. #id or .class) for the DOM element to
//               update with the payload regardless of success or failure
//
// Triggers an ajaxDomUpdate event to allow other libraries to attach their hooks
// to the new DOM objects
//
// Dependent on: jquery, @rails/ujs

import $ from "jquery";
import Rails from "@rails/ujs";

const throttledUpdate = function () {
  // Keyup events only trigger once every 0.5s
  if (this.wait !== true) {
    Rails.fire(this, "submit");
    this.wait = true;
    setTimeout(() => {
      this.wait = false;
    }, 500);
  }
};

const updateDom = (targetField) =>
  function ({ detail: [, , xhr] }) {
    const target = this.dataset[targetField] || this.dataset.update;
    $(target).html(xhr.responseText);
    $(document.body).trigger("ajaxDomUpdate", target);
  };

const updateDomSuccess = updateDom("success");
const updateDomError = updateDom("failure");

const attachEvents = () => {
  $("a[data-remote=true]")
    .on("ajax:beforeSend", function () {
      $(this.dataset.throbber || "#update_loader").show();
      $(this.dataset.update).html("");
    })
    .on("ajax:complete", function () {
      $(this.dataset.throbber || "#update_loader").hide();
    })
    .on("ajax:success", updateDomSuccess)
    .on("ajax:error", updateDomError);

  $(".remote-form")
    .on("ajax:beforeSend", function () {
      $(this.dataset.throbber || "#update_loader").show();
      $(this).find(".btn").attr("disabled", "disabled");
    })
    .on("ajax:complete", function () {
      $(this.dataset.throbber || "#update_loader").hide();
      $(this).find(".btn").removeAttr("disabled");
    })
    .on("ajax:success", updateDomSuccess)
    .on("ajax:error", updateDomError);

  $(".observed").on("keyup", throttledUpdate).on("change", throttledUpdate);

  // Trigger automatic loading if already flagged as active
  Rails.fire($("a[data-remote=true].active")[0], "click");
};

$(attachEvents);
