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

    if ($(pane).hasClass('completed')) {
      $('#wizard-next').removeAttr('disabled');
    }

    // Check for the Previous button
    if ($(pane).prev('li').length === 0) {
      $('#wizard-previous').attr('disabled', 'disabled');
    } else {
      $('#wizard-previous').removeAttr('disabled');
    }
  };

  var markStageComplete = function(pane) {
    var remainingStages = $('.wizard-pane:visible').next('li').length;

    $(pane).addClass('completed');

    $('#submission-breadcrumbs li.active-stage').addClass('completed-stage');

    //TODO should be part of checkButtons
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

  var markStageIncomplete = function(pane) {
    $(pane).removeClass('completed');
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

  var validateSelection = function(event) {
    var currentPane = $('.wizard-pane:visible');

    var incompleteFieldCount = currentPane.
      find('input, select').
      filter(function(){
        return $(this).val() === "";
      }).length;

    if (incompleteFieldCount === 0) {
      markStageComplete(currentPane);
    } else if (incompleteFieldCount >= 1) {
      markStageIncomplete(currentPane);
    }
  };


  // Document Ready stuff...
  $(function(){
    $('#submission_template_id').change(orderParameterHandler);

    $('#submission_project_name').autocomplete({
      source    : SCAPE.user_project_names,
      minLength : 3,
      select    : projectSelectHandler

      // change event needs to check whether the select event fired...
      // change    : function() { 
      //   $('#project-details').fadeOut().html(""); 
      //   markStageIncomplete();
      // }
    });


    $('#submission_study_id').change(studySelectHandler);


    $('#wizard-next').click(nextPaneHandler);
    $('#wizard-previous').click(previousPaneHandler);
    $('.required').live('change',  validateSelection);
  });

})(jQuery);

