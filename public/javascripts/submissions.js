(function($, undefined){
  var orderParameterHandler = function(event){
    var submission_details = {
      submission: {
        submission_template_id: $(this).val()
      }
    };

    // Load the parameters for the new order
    $.get(
      '/submissions/order_parameters',
      submission_details,
      function(data) {
        $('#submission-parameters').html(data).fadeIn();
      }
    );
  }

  var checkButtons = function(pane) {
    // Check for then Next button
    if ($(pane).next('li').length == 0) {
      $('#wizard-next').attr('disabled', 'disabled');
      $('#start-submission').removeAttr('disabled');
    } else {
      $('#wizard-next').removeAttr('disabled');
      $('#start-submission').attr('disabled', 'disabled');
    }

    // Check for the Previous button
    if ($(pane).prev('li').length == 0) {
      $('#wizard-previous').attr('disabled', 'disabled');
    } else {
      $('#wizard-previous').removeAttr('disabled');
    }
  }

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

    return false;
  }

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

    return false;
  }

  $(function(){
    $('#submission_submission_template_id').change(orderParameterHandler);
    $('#wizard-next').click(nextPaneHandler);
    $('#wizard-previous').click(previousPaneHandler);
  });

})(jQuery);

