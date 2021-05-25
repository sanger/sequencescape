(function ($, undefined) {
  "use strict";

  function contentFor(tab) {
    var content = $("li[data-tab-content='" + $(tab).data("tab-refers") + "']");
    if (content.length == 0) {
      return $($(tab).data("tab-refers"));
    } else {
      return content;
    }
  }

  function selectTab(tab) {
    $(tab).addClass("active");
    contentFor(tab).show();
  }

  function unselectTab(tab) {
    $(tab).removeClass("active");
    contentFor(tab).hide();
  }

  function dataTabGroupHandler(node) {
    return function (event) {
      if (typeof $(node).data("tab-refers") === "undefined") {
        $("[data-tab-group=" + $(node).data("tab-group") + "]").each(function (pos, checkedNode) {
          if (checkedNode === node) {
            selectTab($(checkedNode));
          } else {
            unselectTab($(checkedNode));
          }
        });
        return;
      }
      $("[data-tab-group=" + $(node).data("tab-group") + "]").each(function (pos, checkedNode) {
        if ($(checkedNode).data("tab-refers") !== $(node).data("tab-refers")) {
          unselectTab($(checkedNode));
        } else {
          selectTab($(checkedNode));
        }
      });
      selectTab($(node));
    };
  }

  var attachEvents;

  attachEvents = function () {
    $(document).on("click", "[data-tab-group]", function (e) {
      return dataTabGroupHandler.call(this, e.target).call(this, e);
    });

    $("[data-tab-group]").each(function (pos, node) {
      var li = $(node).parent();
      // Tab selection behaviour
      li.on("click", dataTabGroupHandler(node));

      // Loads the content of the selected tab
      if (li.hasClass("selected") || $(node).hasClass("selected")) {
        $("a", li).trigger("click");
      }
    });
  };

  $(document).ready(attachEvents);
})(jQuery);
