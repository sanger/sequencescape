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
    }

    // Check for the Previous button
    if ($(pane).prev('li').length === 0) {
      $('#wizard-previous').attr('disabled', 'disabled');
    } else {
      $('#wizard-previous').removeAttr('disabled');
    }
  };

  var completeStage = function() {
    var remainingStages = $('.wizard-pane:visible').next('li').length;

    $('#submission-breadcrumbs li.active-stage').addClass('completed-stage');

    if ( remainingStages === 0) {
      // We're on the last pane of the wizard...
      $('#wizard-next').attr('disabled', 'disabled');
      $('#start-submission').removeAttr('disabled');

      return true;

    } else if ( remainingStages >= 1) {
      // We've just completed one of the other panes...
      $('#wizard-next').removeAttr('disabled');
      $('#start-submission').attr('disabled', 'disabled');
      return true;
    }

    // Well we're not in Kansas anymore...
    return false;
  };

  var uncompleteStage = function() {
    $('#submission-breadcrumbs li.active-stage').removeClass('completed-stage');
    $('#wizard-next, #start-submission').attr('disabled', 'disabled');
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
  var studySelectHandler = function(event) {
    SCAPE.submission.study_id = $(this).val();

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
    SCAPE.submission.project_name = $(this).val();

    $.get(
      '/submissions/project_details',
      { submission : SCAPE.submission },
      function(data) {
        $('#project-details').html(data);
        $('#start-submission').removeAttr('disabled');
      }
    );
  };

  var validateSelection = function(event) {
    var incompleteFieldCount = $('.wizard-pane:visible').
      find('input, select').
      filter(function(){
        return $(this).val() === "";
      }).length;

    if (incompleteFieldCount === 0) {
      completeStage();
    } else if (incompleteFieldCount >= 1) {
      uncompleteStage();
    }
  };


  // Document Ready stuff...
  $(function(){
    $('#submission_template_id').change(orderParameterHandler);

    $('#submission_project_name').autocomplete({
      source    : SCAPE.user_project_names,
      minLength : 3,
      select    : projectSelectHandler
    });

    $('#submission_study_id').change(studySelectHandler);


    $('#wizard-next').click(nextPaneHandler);
    $('#wizard-previous').click(previousPaneHandler);
    $('.required').live('change',  validateSelection);
  });

})(jQuery);

