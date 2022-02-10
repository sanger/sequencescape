// Submission workflow jQuery Plugin...
(function (window, $, undefined) {
  "use strict";

  var templateChangeHandler = function (event) {
    var submissionTemplateId = $(event.currentTarget).val();

    $("#order-parameters").slideUp(100, function () {
      // Load the parameters for the new order
      $.get("/bulk_submission_excel_downloads/new", { submission_template_id: submissionTemplateId }, function (data) {
        $("#order-parameters").html(data);
        $("#order-parameters").show(100);
      });
      return true;
    });
  };

  // Document Ready stuff...
  $(function () {
    $("#bulk_submission_excel_download_submission_template_id").on("change", templateChangeHandler);
  });
})(window, jQuery);
