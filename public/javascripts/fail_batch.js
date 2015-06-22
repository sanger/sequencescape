//This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
//Please refer to the LICENSE and README files for information on licensing and authorship of this file.
//Copyright (C) 2013 Genome Research Ltd.
(function(window,$,undefined) {
  'use strict';

  $(function(){
    $('.select_all').bind(
      'change', function() {
        var target
        if (this.dataset.action) {
          target = '.select_' + this.dataset.action;
        } else {
          target = '.select_all_target';
        }
        $(target).attr('checked',this.checked);
      }
    );
  });


})(window,jQuery)
