(function($, undefined){
  // Name spacing stuff...
  if ( window.SCAPE === undefined) { window.SCAPE = {}; }

  if ( SCAPE.submission_details === undefined) { SCAPE.submission = {}; }


  var templateChangeHandler = function(event){
    markStageIncomplete();
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
    markStageIncomplete();
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

    $.get(
      '/submissions/project_details',
      { submission : SCAPE.submission },
      function(data) {
        $('#project-details').html(data);
        if (SCAPE.submission.order_valid) {
          markStageComplete();
        }
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

  var markStageComplete = function(pane) {
    $(pane).
      addClass('completed').
      removeClass('active').
      find('input, select').attr('disabled', 'true');

    $(pane).next('li').
      addClass('active').
      find('input, select').removeAttr('disabled');
    return true;
  };

  var markStageIncomplete = function(pane) {
    $(pane).removeClass('completed');
    return false;
  };

  var validateSection = function(event) {
    var currentPane = $(this).closest('#orders li');

    return allFieldsComplete(currentPane)?
      markStageComplete(currentPane) : markStageIncomplete(currentPane);
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
  });

})(jQuery);

