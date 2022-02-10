// Sets up AJAX functionality for links to allow AJAX updating of page elements
//
// Binds to: links with the attribute data-remote=true
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

const attachEvents = () => {
  $("a[data-remote=true]")
    .on("ajax:beforeSend", function () {
      $(this.dataset.throbber || "#update_loader").show();
      $(this.dataset.update).html("");
    })
    .on("ajax:complete", function () {
      $(this.dataset.throbber || "#update_loader").hide();
    })
    .on("ajax:success", function ({ detail: [, , xhr] }) {
      const target = this.dataset.success || this.dataset.update;
      $(target).html(xhr.responseText);
      $(document.body).trigger("ajaxDomUpdate", target);
    })
    .on("ajax:error", function ({ detail: [, , xhr] }) {
      const target = this.dataset.failure || this.dataset.update;
      $(target).html(xhr.responseText);
    });
};

$(attachEvents);
