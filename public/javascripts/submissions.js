(function($, undefined){
  // Name spacing stuff...
  if ( window.SCAPE === undefined) { window.SCAPE = {}; }

  if ( SCAPE.submission_details === undefined) { SCAPE.submission = {}; }


  var templateChangeHandler = function(event){
    markPaneIncomplete();
    // When there's nothing selected reset the parameters element and exit without 
    if ($(this).val() === "") {
      delete SCAPE.submission.template_id;
      $('#order-parameters').html('');
      return false;
    }

    SCAPE.submission.template_id = $(this).val();

    // Load the parameters for the new order
    $.get(
      '/submissions/order_parameters',
      { submission: SCAPE.submission },
      function(data) {
        $('#order-parameters').html(data).fadeIn();
      }
    );
    return true;
  };


  // This handler depends on the study template being set earlier in the wizard.
  var studySelectHandler = function(event) {
    markPaneIncomplete();
    SCAPE.submission.study_id = $(this).val();

    if ($(this).val().length > 0) {

      // Load asset groups for the selected study
      $.get(
        '/submissions/study_assets',
        { submission : SCAPE.submission },
        function(data) {
          $('#study-assets').fadeOut().html(data).fadeIn();
        }
      );
      return true;
    } else {
      $('#study-assets').fadeOut().html("");
      return false;
    }

  };

  var projectSelectHandler = function(event) {
    SCAPE.submission.project_name = $(this).val();
    SCAPE.submission.asset_group_id = $('#submission_asset_group_id').val();

    var currentPane = $(this).closest('.order');

    $.post(
      '/submissions',
      { submission : SCAPE.submission },
      function(data) {
        currentPane.find('.project-details').html(data);

        SCAPE.submission.order_valid?
          markPaneComplete(currentPane) : markPaneInvalid(currentPane);
      }
    );
  };


  // Returns true if all the input fields in a pane have a value
  var allFieldsComplete = function(pane) {
      // This won't work in old IE versions <9.
      // If we need to support old IE add a conditional enhancement
      // to the start of the module...
    return pane.find('input, select').toArray().
      every(function(element){ return $(element).val(); });
  };

  var markPaneComplete = function(pane) {
    $(pane).
      addClass('completed');
      // find('input, select').attr('disabled', 'true');

    // $(pane).next('li').
    //   addClass('active').
    //   // find('.assets').
    //   find('input, select').removeAttr('disabled');
    $('#add-order').removeAttr('disabled');

    return true;
  };

  var markPaneIncomplete = function(pane) {
    $(pane).removeClass('completed');
    $('#add-order').attr('disabled',true);
    return false;
  };

  var markPaneInvalid = function(pane) {
    $(pane).addClass('invalid');
  };

  var validateSection = function(event) {
    var currentPane = $(this).closest('#orders li');

    return allFieldsComplete(currentPane)?
      markPaneComplete(currentPane) : markPaneIncomplete(currentPane);
  };


  // Document Ready stuff...
  $(function(){
    $('#submission_template_id').change(templateChangeHandler);

    $('#submission_project_name').autocomplete({
      source    : SCAPE.user_project_names,
      minLength : 3,
      select    : projectSelectHandler
    });


    $('#submission_study_id').change(studySelectHandler);


    $('#order-parameters .required').live('change',  validateSection);

    $(".order").live("scape.order.valid", function(event){
      $(this).addClass('completed');
    });

  });

})(jQuery);

