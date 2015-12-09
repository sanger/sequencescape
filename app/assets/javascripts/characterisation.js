//This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
//Please refer to the LICENSE and README files for information on licensing and authorship of this file.
//Copyright (C) 2011 Genome Research Ltd.
(function($, undefined) {
  $(document).ready(function(){
    // Stop the default values form from submitting...
    $('#default-values').submit(function () { return false; });

    $('#copy-defaults').click(function(){

      //find all default values copy their values to the corresponding input values
      $('input.default-value').each(function(){
        var descriptorName = $(this).data('default-for');
        var newDefaultValue = $(this).val();

        if (newDefaultValue != "") {
          $('input[data-descriptor-for=' + descriptorName + ']').val(newDefaultValue).hide().fadeIn('slow');
        }
      });
    });

    $('#clear-desrciptors').click(function() {
      $('input.descriptor-value').val('');
    });

    $("input.descriptor-value").bind("keydown", function(e) {
      var code=e.charCode || e.keyCode;

      // Trap enter key to move to the next similar descriptor field.
      if (code == 13){
        var descriptorFor = $(this).data('descriptor-for');
        var field_index = $('[data-descriptor-for=' + descriptorFor + ']' ).index(this);

        field_index +=  1;

        // Set focus to new field
        $('[data-descriptor-for=' + descriptorFor + ']')[field_index].focus();

      return false;
      }
    });
  });
})(jQuery);
