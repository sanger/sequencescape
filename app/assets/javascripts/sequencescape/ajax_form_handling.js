//This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
//Please refer to the LICENSE and README files for information on licensing and authorship of this file.
//Copyright (C) 2015 Genome Research Ltd.

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

  attachEvents = function(){
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
      attachEvents();
    }).bind('ajax:error', function(xhr, data, status) {
      var target;
      target = this.dataset.failure ||  this.dataset.update;
      $(target).html(data);
      attachEvents();
    });

    $('.observed').bind('keyup',throttledUpdate).bind('change',throttledUpdate)
  };

  $(document).ready( attachEvents );

})(jQuery);
