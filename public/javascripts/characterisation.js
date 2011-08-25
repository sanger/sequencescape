jQuery(document).ready(function(){
  // Stop the default values form from submitting...
  jQuery('#default-values').submit(function () { return false; }); 

  jQuery('#copy-defaults').click(function(){

    //find all default values copy their values to the corresponding input values
    jQuery('input.default-value').each(function(){
      var descriptorName = jQuery(this).data('default-for');
      var newDefaultValue = jQuery(this).val();

      if (newDefaultValue != "") {
        jQuery('input[data-descriptor-for=' + descriptorName + ']').val(newDefaultValue).hide().fadeIn('slow');
      }
    });
  });

  jQuery('#clear-desrciptors').click(function() {
    jQuery('input.descriptor-value').val('');
  });

  jQuery("input.descriptor-value").bind("keydown", function(e) {
    var code=e.charCode || e.keyCode;

    // Trap enter key to move to the next similar descriptor field.
    if (code == 13){
      var descriptorFor = jQuery(this).data('descriptor-for');
      var field_index = jQuery('[data-descriptor-for=' + descriptorFor + ']' ).index(this);

      field_index +=  1;

      // Set focus to new field
      jQuery('[data-descriptor-for=' + descriptorFor + ']')[field_index].focus();

    return false;
    }
  });
});
