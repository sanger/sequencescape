

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
