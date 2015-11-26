//This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
//Please refer to the LICENSE and README files for information on licensing and authorship of this file.
//Copyright (C) 2015 Genome Research Ltd.

( function($, undefined){
  "use strict";
  $(document).ready(function(){
    $('.remote-form').bind("ajax:beforeSend",  function(){
      $(this).find('.btn').attr('disabled','disabled');
    })
    .bind("ajax:complete", function(){
      $(this).find('.btn').removeAttr('disabled');
    })
    .bind("ajax:success", function(xhr, data, status) {
      var target;
      target = this.dataset.success ||  this.dataset.update;
      $(target).html(data);
    }).bind('ajax:error', function(xhr, data, status) {
      var target;
      target = this.dataset.failure ||  this.dataset.update;
      $(target).html(data);
    });
  });
})(jQuery);
