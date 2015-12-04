//This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
//Please refer to the LICENSE and README files for information on licensing and authorship of this file.
//Copyright (C) 2015 Genome Research Ltd.

( function($, undefined){
  "use strict";

  var attachEvents;

  attachEvents = function(){
    $("[data-tab-group]").each(function(pos, node) {
      var li = $(node).parent();
      // Tab selection behaviour
      li.on("click", function(event, object) {
        $("[data-tab-group="+ $(node).data('tab-group') +"]").each(function(pos, n) {
          $(n).parent().removeClass("selected");
        });
        li.addClass("selected");
      });

      // Loads the content of the selected tab
      if (li.hasClass("selected")) {
        $("a", li).trigger("click");
      };
    });
  };

  $(document).ready( attachEvents );

})(jQuery);
