

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
