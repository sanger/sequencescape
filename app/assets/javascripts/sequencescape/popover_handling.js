(function ($, undefined) {
  var attachEvents;

  attachEvents = function(){
    $('[data-toggle="popover"]').popover({
      trigger: 'hover',
      html: 'true'
    });
  };

  $(document).ready(attachEvents);
})(jQuery);
