//This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
//Please refer to the LICENSE and README files for information on licensing and authorship of this file.
//Copyright (C) 2016 Genome Research Ltd.
(function() {
  var attachEvents = function() {
    $('header nav ul.nav li').filter(function(pos, n) {
      if (window.location.href.match($('a', n).attr('href'))!==null) {
        return true;
      };
    }).first().addClass('active');
  };
  $(document).ready(attachEvents);
})();
