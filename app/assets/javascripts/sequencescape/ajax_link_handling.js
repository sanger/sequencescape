//This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
//Please refer to the LICENSE and README files for information on licensing and authorship of this file.
//Copyright (C) 2015 Genome Research Ltd.

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
      $(document.body).trigger("ajaxDomUpdate");
    }).bind('ajax:error', function(xhr, data, status) {
      var target = this.dataset.failure ||  this.dataset.update;
      $(target).html(data);
    });
  };

  $(document).ready( attachEvents );

})(jQuery);
