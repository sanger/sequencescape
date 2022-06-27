// Submission workflow jQuery Plugin...
(function (window, $) {
  "use strict";

  var methods = {
    init: function (_options) {
      return this;
    },

    // Returns true if the input fields in a pane have a value
    allFieldsComplete: function (_pane) {
      // This is not very pretty but it is IE safe...
      var validationResult = true;
      this.find("input.required").each(function (_element) {
        if (!$(this).val().match(/^\d+$/)) {
          validationResult = false;
        }
      });

      return validationResult;
    },

    hasAssets: function () {
      if (
        this.find(".submission_asset_group_id").val() ||
        this.find(".submission_sample_names_text").val() ||
        this.find(".submission_barcodes_wells_text").val()
      ) {
        return true;
      } else {
        return false;
      }
    },

    currentPane: function () {
      return this.closest(".pane");
    },

    loadStudyAssets: function (submission) {
      var element = this;

      $.get("/submissions/study_assets", { submission: submission }, function (data) {
        element.find(".study-assets").fadeOut(function () {
          $(this).html(data).fadeIn();
        });
      });

      return this;
    },

    markPaneIncomplete: function () {
      this.addClass("section-in-progress").removeClass("section-complete section-error");

      // Move this to an initialised callback
      $("#add-order").attr("disabled", true);

      return this;
    },

    markPaneInvalid: function () {
      return this.addClass("section-error").removeClass("section-in-progress section-complete");
    },

    markPaneComplete: function () {
      this.addClass("section-complete").removeClass("section-in-progress section-error").find("input, select");

      // Move this to an initialised callback
      this.find(".save-order, .cancel-order").hide();

      // Move this to an initialised callback
      $("#add-order").removeAttr("disabled");

      return this;
    },
  };

  $.fn.submission = function (method) {
    if (methods[method]) {
      return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
    } else if (typeof method === "object" || !method) {
      return methods.init.apply(this, arguments);
    } else {
      return $.error("Method " + method + " does not exist on jQuery.submission");
    }
  };
})(window, window.jQuery);

// Submission page code...
(function (window, $) {
  "use strict";
  // Name spacing stuff...
  if (window.SCAPE === undefined) window.SCAPE = {};

  if (window.SCAPE.submission === undefined) {
    window.SCAPE.submission = {
      order_params: {},
    };
  }

  var templateChangeHandler = function (event) {
    var currentPane = $(event.currentTarget).submission("currentPane");

    delete window.SCAPE.submission.template_id;

    $("#order-parameters").slideUp(100, function () {
      $(this).html("");
      currentPane.submission("markPaneIncomplete");

      if ($(event.currentTarget).val()) {
        window.SCAPE.submission.template_id = $(event.currentTarget).val();

        // Load the parameters for the new order
        $.get("/submissions/order_fields", { submission: window.SCAPE.submission }, function (data) {
          $("#order-parameters").html(data);

          currentPane.submission("allFieldsComplete")
            ? currentPane.submission("markPaneComplete")
            : currentPane.submission("markPaneIncomplete");

          $("#order-parameters").show(100);
        });
        return true;
      }
    });
  };

  var studySelectHandler = function (event) {
    // This handler depends on the study template being set earlier in the wizard.
    var currentPane = $(event.target).submission("currentPane");

    currentPane.submission("markPaneIncomplete");

    window.SCAPE.submission.study_id = $(event.target).val();

    if ($(event.target).val().length > 0) {
      // Load asset groups for the selected study
      currentPane.submission("loadStudyAssets", window.SCAPE.submission);
    } else {
      // The study selector has been reset so fade out and reset the field.
      currentPane.find(".study-assets").fadeOut(function () {
        $(this).html("");
      });
    }
  };

  var saveOrderHandler = function (_event) {
    var currentPane = $(this).submission("currentPane");
    // refactor this little lot!
    window.SCAPE.submission.project_name = currentPane.find(".submission_project_name").val();
    window.SCAPE.submission.asset_group_id = currentPane.find(".submission_asset_group_id").val();
    window.SCAPE.submission.sample_names_text = currentPane.find(".submission_sample_names_text").val();
    window.SCAPE.submission.barcodes_wells_text = currentPane.find(".submission_barcodes_wells_text").val();
    window.SCAPE.submission.plate_purpose_id = currentPane.find(".submission_plate_purpose_id").val();
    window.SCAPE.submission.comments = currentPane.find(".submission_comments").val();
    window.SCAPE.submission.lanes_of_sequencing_required = currentPane.find(".lanes_of_sequencing").val();
    window.SCAPE.submission.order_params.gigabases_expected = currentPane.find(".gigabases_expected").val();
    window.SCAPE.submission.order_params.pre_capture_plex_level = currentPane.find(".pre_capture_plex_level").val();
    window.SCAPE.submission.pre_capture_plex_group = currentPane.find(".pre_capture_plex_group").val();

    window.SCAPE.submission.priority = $("#submission_priority").val();

    $.post("/submissions", { submission: window.SCAPE.submission }, function (data) {
      currentPane.fadeOut(function () {
        currentPane.detach().html(data).submission("markPaneComplete").removeClass("order-active invalid");

        $("#order-controls").before(currentPane);
        currentPane.fadeIn();

        $("#build-form").attr("action", "/submissions/" + window.SCAPE.submission.id);
        $("#start-submission").removeAttr("disabled");

        $(".pane").not("#blank-order").addClass("order-active");
      });
    }).fail(function (response) {
      currentPane.find(".project-details").html(response.responseText);
      currentPane.submission("markPaneInvalid");
    });

    // don't forget to stop the form submitting...
    return false;
  };

  var validateOrderParams = function (event) {
    var currentPane = $(event.target).submission("currentPane");

    return currentPane.submission("allFieldsComplete")
      ? currentPane.submission("markPaneComplete")
      : currentPane.submission("markPaneIncomplete");
  };

  // Validate that an order has a Project, Study and some Assets.
  var validateOrder = function (event) {
    var currentPane = $(event.target).submission("currentPane");

    var studyId = currentPane.find(".study_id").val() || currentPane.find(".cross_study").attr("checked");

    // TODO This should validate that the project name is in the list but the
    // autocomplete callback doesn't seem to fire properly so this is a bit of
    // a kludge around that.
    var projectName =
      currentPane.find(".submission_project_name").val() || currentPane.find(".cross_project").attr("checked");
    var hasAssets = currentPane.submission("hasAssets");

    if (studyId && projectName && hasAssets) {
      currentPane.find(".save-order").removeAttr("disabled");
    } else {
      currentPane.find(".save-order").attr("disabled", true);
    }
  };

  var getParamName = function (param) {
    return $(param).attr("id").replace("submission_order_params_", "");
  };

  var addOrderHandler = function (_event) {
    // Loads this order's parameters into thewindow.SCAPE.submission object...
    $("#order-parameters")
      .find("select, input")
      .each(function () {
        window.SCAPE.submission.order_params[getParamName(this)] = $(this).val();
      });

    // Mask out the order template parameters so that they can't be
    // changed once an order has been added.
    $("#order-template").find("select, input").attr("disabled", true);

    $(".order-active").removeClass("order-active");

    // Stop the submission from being built until new the order is either
    // saved or cancelled...
    $("#start-submission").attr("disabled", true);

    $("#add-order").attr("disabled", true);

    var newOrder = $("<li>").html($("#blank-order").html()).addClass("pane order-active order").hide();

    // Remove the disable from the form inputs
    // but leave the save button disabled
    newOrder
      .find("input, select, textarea")
      .not(".save-order")
      .css("opacity", 1)
      .removeAttr("disabled")
      .prop("disabled", false);

    // Enable the cross study/project buttons if appropriate
    if (window.SCAPE.submission.cross_compatible === false) {
      newOrder.find(".cross-compatible").remove();
    }

    newOrder.find(".cross_study").bind("change", function (e) {
      newOrder.find(".study_id").prop("disabled", this.checked);
      newOrder.find(".study_id option:eq(0)").prop("selected", true);
      validateOrder(e);
    });

    newOrder.find(".cross_project").bind("change", function (e) {
      newOrder.find(".submission_project_name").prop("disabled", this.checked);
      newOrder.find(".submission_project_name").prop("value", null);
      validateOrder(e);
    });
    // if this is not a sequencing order remove the lanes_of_sequencing_required stuff
    if (window.SCAPE.submission.is_a_sequencing_order === false) {
      newOrder.find(".lanes-of-sequencing").remove();
    }

    // we only need this box if we're pre-cap pooling
    if (window.SCAPE.submission.pre_capture_plex_level === null) {
      newOrder.find(".pre-capture-plex-level").remove();
      newOrder.find(".pre-capture-plex-group").remove();
    } else {
      newOrder.find(".pre_capture_plex_level").value = window.SCAPE.submission.pre_capture_plex_level;
      newOrder.find(".pre_capture_plex_level").value = window.SCAPE.submission.pre_capture_plex_group;
    }

    newOrder.find(".submission_project_name").autocomplete({
      source: window.SCAPE.user_project_names,
      minLength: 3,
    });

    // And gigabase stuff is only for library creation
    if (window.SCAPE.submission.show_gigabses_expected === false) {
      newOrder.find(".gigabases-expected").remove();
    }

    // If we already have a study id set then load the asset_group for it.
    // e.g. someone coming to the page directly from a study page rather than
    // the submission inbox.
    if (window.SCAPE.submission.study_id) {
      newOrder.submission("loadStudyAssets", window.SCAPE.submission);
    }

    $("#blank-order").before(newOrder);

    newOrder.slideDown();

    newOrder.find("select").select2({ theme: "bootstrap4" });
  };

  var cancelOrderHandler = function (event) {
    var currentPane = $(event.target).submission("currentPane");

    currentPane.slideUp(function () {
      currentPane.remove();
      if ($(".order.completed").length === 0) {
        $("#order-template").addClass("order-active").find("select, input").removeAttr("disabled");
      }

      $("#add-order").removeAttr("disabled");

      if ($(".order.completed").length !== 0) {
        $("#start-submission").removeAttr("disabled");
      }
    });

    // don't forget to stop the form submitting...
    return false;
  };

  var deleteOrderHandler = function (event) {
    var currentPane = $(event.target).submission("currentPane");

    $.post(
      "/orders/" + currentPane.find(".order-id").val(),
      {
        _method: "delete",
        id: currentPane.find(".order-id").val(),
      },
      function (_response) {
        currentPane.slideUp(function () {
          currentPane.remove();
          $("#add-order").removeAttr("disabled");

          if ($(".order.completed").length === 0) {
            // If we're on an edit page and someone deletes the last order
            // then the submission has also been deleted so redirect them to
            // the submission inbox.
            if (window.location.pathname.match(/\/submissions\/\d+\/edit/)) {
              window.location.replace(window.SCAPE.submissions_inbox_url);
            }

            delete window.SCAPE.submission.id;

            $("#order-template").addClass("order-active").find("select, input").removeAttr("disabled");

            $("#start-submission").attr("disabled", true);
          }
        });
      }
    );

    // don't forget to stop the form submitting...
    return false;
  };

  // Document Ready stuff...
  $(function () {
    // Initialise the #start-submission button.
    $("#start-submission").attr("disabled", true);

    // Initialise the template selector and attach a change handler to
    // it.
    $("#submission_template_id").on("change", templateChangeHandler);

    // Validate the order-parameters
    $("#order-parameters").on("keypress", ".required", validateOrderParams);
    $("#order-parameters").on("blur", ".required", validateOrderParams);

    $("#add-order").click(addOrderHandler);

    // If there are any completed orders then enable the add-order button so we
    // can add more...
    if ($(".order.completed").length) $("#start-submission").removeAttr("disabled");
    // Uncomment for multiple orders
    // if ($('.order.completed').length) $('#add-order, #start-submission').removeAttr('disabled');

    // NB.  There seems to being some odd behaviour related to the
    // autocompleter select callback firing.  As a kludgey fix validation is
    // triggered on field key presses as a supplementary validation.
    $("ul#orders")
      .delegate("li.order select, li.order input, li.order textarea", "blur", validateOrder)
      .delegate(".sample_names_text, li.order input", "keypress", validateOrder)
      .delegate("li.order select", "change", validateOrder);

    // Most of the event handlers can be hung from the orders list...
    // NB. If we upgrade from jQuery 1.6.x to >= 1.7 then we may want to swap
    // out .delegate() to use the .on() function instead.
    $("ul#orders")
      .on("change", ".study_id", studySelectHandler)
      .on("click", ".cancel-order", cancelOrderHandler)
      .on("click", ".save-order", saveOrderHandler)
      .on("click", ".delete-order", deleteOrderHandler);
  });
})(window, window.jQuery);
