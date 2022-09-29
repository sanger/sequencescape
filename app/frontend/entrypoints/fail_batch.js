(function (window, $) {
  "use strict";

  $(function () {
    $(".select_all").bind("change", function () {
      var target;
      if (this.dataset.action) {
        target = ".select_" + this.dataset.action;
      } else {
        target = ".select_all_target";
      }
      $(target).attr("checked", this.checked);
    });
  });
})(window, window.jQuery);
