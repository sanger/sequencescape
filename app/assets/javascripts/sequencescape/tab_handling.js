//This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
//Please refer to the LICENSE and README files for information on licensing and authorship of this file.
//Copyright (C) 2015 Genome Research Ltd.

( function($, undefined){
  "use strict";

  function contentFor(tab) {
    var content = $("[data-tab-content="+$(tab).data("tab-refers")+"]");
    if (content.length == 0) {
      return $($(tab).data("tab-refers"));
    } else {
      return content;
    }
  }

  function selectTab(tab) {
    $(tab).parent().addClass("selected");
    contentFor(tab).show();
  }


  function unselectTab(tab) {
    $(tab).parent().removeClass("selected");
    contentFor(tab).hide();
  }


  var attachEvents;

  attachEvents = function(){
    $(document).on("click", "[data-tab-group]", function(e) {
      var node = e.target
      var li = $(node).parent();
      $("[data-tab-group="+ $(node).data('tab-group') +"]").each(function(pos, n) {
          unselectTab($(n));
      });
      selectTab($(node));
    });

    $("[data-tab-group]").each(function(pos, node) {
      var li = $(node).parent();
      // Tab selection behaviour
      li.on("click", function(event, object) {
        $("[data-tab-group="+ $(node).data('tab-group') +"]").each(function(pos, n) {
          unselectTab($(n));
        });
        selectTab($(node));
      });

      // Loads the content of the selected tab
      if (li.hasClass("selected") || $(node).hasClass("selected")) {
        $("a", li).trigger("click");
      };
    });
  };

  $(document).ready( attachEvents );

})(jQuery);
