//This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
//Please refer to the LICENSE and README files for information on licensing and authorship of this file.
//Copyright (C) 2016 Genome Research Ltd.


( function($, undefined){
  "use strict";

  var attachEvents;

  attachEvents = function(){
    $('.show-comment').on('click',function(){
      $(this.dataset.commentField).slideDown();
    })
    $('.hide-comment').on('click',function(){
      $(this.dataset.commentField).slideUp();
    })
  };

  $(document).ready( attachEvents );

})(jQuery);
