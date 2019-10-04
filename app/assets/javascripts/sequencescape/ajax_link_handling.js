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
// Dependent on: jquery, jquery-ujs
( function($, undefined){
  "use strict";

  var attachEvents;

  attachEvents = function(){
    $('a[data-remote=true]').bind("ajax:beforeSend",  function(){
      $(this.dataset.throbber || '#update_loader').show();
      $(this.dataset.update).html('');
    })
    .bind("ajax:complete", function(){
      $(this.dataset.throbber || '#update_loader').hide();
    })
    .bind("ajax:success", function(xhr, data, status) {
      var target = this.dataset.success ||  this.dataset.update;
      $(target).html(data);
      $(document.body).trigger("ajaxDomUpdate", target);
    }).bind('ajax:error', function(xhr, data, status) {
      var target = this.dataset.failure ||  this.dataset.update;
      $(target).html(data);
    });
  };

  $(document).ready( attachEvents );

})(jQuery);
