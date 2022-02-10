function select_requests_by_group(elementId, size, value) {
  for (var i = 1; i < size + 1; i++) {
    $("#" + elementId + "_" + i + " input[type=checkbox]")[0].checked = value;

    element = $("#" + elementId + "_" + i);
    if (value) {
      element.show();
    } else {
      element.hide();
    }
  }
}

function showElement(elementId, size) {
  for (var i = 0; i < size + 1; i++) {
    element = document.getElementById(elementId + "_" + i);
    if (element && element.style) {
      if (element.style.display == "") element.style.display = "none";
      else element.style.display = "";
    }
  }
}

(function ($, undefined) {
  // Whenever someone clicks on a priority flag we need to change the request priority.  For the multiplexed requests
  // this will trigger all of them to be updated.
  var inbox = $("#pipeline_inbox");
  inbox.delegate(".flag_image.as_manager", "click", function () {
    var element = $(this);

    var priority = parseInt(element.attr("data-priority"));

    $.ajax({
      url: "/pipelines/update_priority",
      type: "POST",
      data: {
        request_id: element.attr("data-request-id"),
      },
      success: function () {
        new_priority = (priority + 1) % 4; // NOTE: Inverted at this point!
        element
          .attr("data-priority", new_priority)
          .attr("alt", new_priority)
          .attr("src", "/images/icon_" + new_priority + "_flag.png");
        inbox.trigger("priorityChange", element);
      },
      error: function () {
        alert("The request cannot be saved properly. Flag not updated.");
      },
    });
  });

  // This handles the priority changing event by signalling table resorting and updating any related flags.
  inbox.bind("priorityChange", function (event, element) {
    element = $(element);
    inbox.trigger("updateCell", element.parent("td")).trigger("reSort");
    $(".related_flag_image[data-submission-id=" + element.attr("data-submission-id") + "]")
      .attr("src", element.attr("src"))
      .attr("alt", element.attr("alt"));
  });
})(jQuery);
