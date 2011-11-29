(function($, undefined){
  // Name spacing stuff...
  if ( window.SCAPE === undefined) { window.SCAPE = {}; }

  if ( SCAPE.submission_details === undefined) { SCAPE.submission = {}; }


  var orderParameterHandler = function(event){
    // When there's nothing selected reset the parameters element and exit without 
    if ($(this).val() === "") {
      delete SCAPE.submission.template_id;
      $('#submission-parameters').html('');
      return false;
    }

    SCAPE.submission.template_id = $(this).val();

    // Load the parameters for the new order
    $.get(
      '/submissions/order_parameters',
      { submission: SCAPE.submission },
      function(data) {
        $('#submission-parameters').html(data).fadeIn();
      }
    );
    return true;
  };

  var checkButtons = function(pane) {
    // Check for then Next button
    if ($(pane).next('li').length === 0) {
      $('#wizard-next').attr('disabled', 'disabled');
      $('#start-submission').removeAttr('disabled');
    } else {
      $('#wizard-next').removeAttr('disabled');
      $('#start-submission').attr('disabled', 'disabled');
    }

    // Check for the Previous button
    if ($(pane).prev('li').length === 0) {
      $('#wizard-previous').attr('disabled', 'disabled');
    } else {
      $('#wizard-previous').removeAttr('disabled');
    }
  };

  var nextPaneHandler = function(event){
    $(this).attr('disabled','disabled');

    $('#submission-breadcrumbs li.active-stage').
      removeClass('active-stage').
      addClass('completed-stage').
      next().
      addClass('active-stage');

    $('.wizard-pane:visible').fadeOut(300, function(){
      $(this).next().fadeIn(300, function(){
        checkButtons(this);
      });
    });

    // Return false so that the form won't submit early.
    return false;
  };

  var previousPaneHandler = function(event){
    $(this).attr('disabled','disabled');

    $('#submission-breadcrumbs li.active-stage').
      removeClass('active-stage').
      prev().
      removeClass('completed-stage').
      addClass('active-stage');


    $('.wizard-pane:visible').fadeOut(300, function(){
      $(this).prev().fadeIn(300, function(){
        checkButtons(this);
      });
    });

    // Return false so that the form won't submit early.
    return false;
  };

  // This handler depends on the study template being set earlier in the wizard.
  var studiesSelectHandler = function(event) {
    SCAPE.submission.study_name = $(this).val();

    // $(event.target).attr('disabled', 'true');

    // Load asset groups for the selected study
    $.get(
      '/submissions/study_assets',
      { submission : SCAPE.submission },
      function(data) {
        $('#study-assets').html(data).fadeIn();
      }
    );
    return true;

  };

  var projectSelectHandler = function(event) {
    debugger;
    SCAPE.submission.project_name = $(this).val();

    $.get(
      '/submissions/project_details',
      { submission : SCAPE.submission },
      function(data) {
        $('#project-details').html(data).fadeIn();
      }
    );
  };


  // Document Ready stuff...
  $(function(){
    $('#submission_template_id').change(orderParameterHandler);

    $('#submission_project_name').autocomplete({
      source    : SCAPE.user_project_names,
      minLength : 3,
      select    : projectSelectHandler
    });

    $('#submission_study_name').autocomplete({
      source    : SCAPE.study_names,
      minLength : 3,
      select    : studiesSelectHandler
    });

    $('#wizard-next').click(nextPaneHandler);
    $('#wizard-previous').click(previousPaneHandler);
  });

})(jQuery);

