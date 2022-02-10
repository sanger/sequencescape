// Sets up AJAX functionality for forms
//
// Binds to: DOM objects with the class remote-form
//           DOM objects with the class observed will submit every 0.5s if data changes
//
// Will use the following data attributes
// data-throbber: A JQuery identifier (eg. #id or .class) for the DOM element
//                representing an in progress spinner to show/hide as a query runs
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

const throttledUpdate = function () {
  // Keyup events only trigger once every 0.5s
  if (this.wait !== true) {
    var formElement = this;
    $(this).trigger("submit.rails");
    formElement.wait = true;
    setTimeout(function () {
      formElement.wait = false;
    }, 500);
  }
};

const attachEvents = function (_) {
  $(".remote-form")
    .on("ajax:beforeSend", function () {
      $(this.dataset.throbber || "#update_loader").show();
      $(this).find(".btn").attr("disabled", "disabled");
    })
    .on("ajax:complete", function () {
      $(this.dataset.throbber || "#update_loader").hide();
      $(this).find(".btn").removeAttr("disabled");
    })
    .on("ajax:success", function ({ detail: [, , xhr] }) {
      const target = this.dataset.success || this.dataset.update;
      $(target).html(xhr.responseText);
      $(document.body).trigger("ajaxDomUpdate", target);
    })
    .on("ajax:error", function ({ detail: [, , xhr] }) {
      const target = this.dataset.failure || this.dataset.update;
      $(target).html(xhr.responseText);
      $(document.body).trigger("ajaxDomUpdate", target);
    });

  $(".observed").on("keyup", throttledUpdate).on("change", throttledUpdate);
};

$(document).ready(attachEvents);
$(document).on("ajaxDomUpdate", attachEvents);
