

( function($, undefined){
  "use strict";

  var attachEvents, throttledUpdate;

  throttledUpdate = function(){
    // Keyup events only trigger once every 0.5s
    if (this.wait !== true ) {
      var formElement = this;
      $(this).trigger("submit.rails");
      formElement.wait = true;
      setTimeout(function(){ formElement.wait = false }, 500);
    }
  };

  attachEvents = function(_){
    $('.remote-form').bind("ajax:beforeSend",  function(){
      $(this.dataset.throbber || '#update_loader').show();
      $(this).find('.btn').attr('disabled','disabled');
    })
    .bind("ajax:complete", function(){
      $(this.dataset.throbber || '#update_loader').hide();
      $(this).find('.btn').removeAttr('disabled');
    })
    .bind("ajax:success", function(xhr, data, status) {
      var target;
      target = this.dataset.success ||  this.dataset.update;
      $(target).html(data);
      $(document.body).trigger("ajaxDomUpdate", target);
    }).bind('ajax:error', function(xhr, data, status) {
      var target;
      target = this.dataset.failure ||  this.dataset.update;
      $(target).html(data);
      $(document.body).trigger("ajaxDomUpdate", target);
    });

    $('.observed').bind('keyup',throttledUpdate).bind('change',throttledUpdate)
  };

  $(document).ready( attachEvents );
  $(document).on('ajaxDomUpdate', attachEvents );

})(jQuery);
