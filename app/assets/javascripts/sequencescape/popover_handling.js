//This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
//Please refer to the LICENSE and README files for information on licensing and authorship of this file.
//Copyright (C) 2015,2016 Genome Research Ltd.
(function ($, undefined) {
  var attachEvents;

  attachEvents = function(){
    $('.popover-trigger[data-toggle="popover"]').popover({
      trigger: 'hover click',
      html: 'true'
    });
  };

  $(document).ready(attachEvents);
})(jQuery);
