(function ($, undefined) {
  var attachEvents;

  attachEvents = function () {
    $('.popover-trigger[data-toggle="popover"]').popover({
      trigger: "hover click",
      html: true,
    });
  };

  $(document).ready(attachEvents);
})(jQuery);
