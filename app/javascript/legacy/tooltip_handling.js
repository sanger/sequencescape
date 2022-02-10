(function ($, undefined) {
  var attachEvents;

  attachEvents = function () {
    $('[data-toggle="tooltip"]').tooltip();
  };

  $(document).ready(attachEvents);
})(jQuery);
