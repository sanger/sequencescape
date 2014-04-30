(function(window,$,undefined) {
  'use strict';

  $(function(){
    $('.select_all').bind(
      'change', function() {
        $('.select_all_target').attr('checked',this.checked);
      }
    );
  });


})(window,jQuery)
