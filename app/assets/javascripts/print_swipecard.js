(function ($, undefined) {
  "use strict";
  $(document).ready(function () {
    $("#print-btn").click(function () {
      var swipecard = $("#swipecard").val().trim();
      var printer_name = $("#barcode-printer-list").find(":selected").val();
      var user_login = $("#usr-data").data("usr-login");
      var pmb_url = $("#pmb-data").data("pmb-api") + "/print_jobs";
      var swipecard_pmb_template_name = $("#pmb-data").data("swipecard_pmb_template");
      var print_job = {
        print_job: {
          printer_name: printer_name,
          label_template_name: swipecard_pmb_template_name,
          labels: [
            {
              left_text: user_login,
              barcode: swipecard,
              label_name: "main",
            },
          ],
        },
      };
      if (swipecard) {
        $.ajax({
          url: pmb_url,
          type: "POST",
          data: JSON.stringify(print_job),
          contentType: "application/vnd.api+json",
          success: function (data) {
            alert("Print Job Sent!");
          },
          failure: function (errMsg) {
            alert(errMsg);
          },
        });
      }
    });
  });
})(jQuery);
