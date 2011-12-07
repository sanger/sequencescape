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
    var currentPane = $(this).closest('#orders > li');

    markPaneIncomplete(currentPane);

    SCAPE.submission.study_id = $(this).val();

    if ($(this).val().length > 0) {

      // Load asset groups for the selected study
      $.get(
        '/submissions/study_assets',
        { submission : SCAPE.submission },
        function(data) {
          currentPane.find('.study-assets').fadeOut(function(){
            $(this).html(data).fadeIn();
          });
        }
      );
      return true;
    } else {
      currentPane.find('.study-assets').fadeOut(function(){
        $(this).html("");
      });
      return false;
    }

  };

  var projectSelectHandler = function(event) {
    var currentPane                 = $(this).closest('.order');
    var projectNameElement          = currentPane.find('.submission_project_name');

    SCAPE.submission.project_name   = projectNameElement.val();
    SCAPE.submission.asset_group_id = $('#submission_asset_group_id').val();


    $.post(
      '/submissions',
      { submission : SCAPE.submission },
      function(data) {
        currentPane.find('.project-details').html(data);

        if(SCAPE.submission.order_valid) {
          currentPane.fadeOut(function(){
            currentPane.detach().removeClass('active');
            markPaneComplete(currentPane);
            $('#order-controls').before(currentPane);
            currentPane.fadeIn();
            $('#blank-order').fadeIn();
          });
        } else {
          markPaneInvalid(currentPane);
        }
      }
    );
  };


  // Change to jQuery method
  // Returns true if a') the input fields in a pane have a value
  var allFieldsComplete = function(pane) {
      // This won't work in old IE versions <9.
      // If we need to support old IE add a conditional enhancement
      // to the start of the module...
    return pane.find('input, select').toArray().
      every(function(element){ return $(element).val(); });
  };

  // Change to jQuery method
  var markPaneComplete = function(pane) {
    $(pane).
      addClass('completed').
      removeClass('invalid').
      find('input, select').attr('disabled', 'true');

    $(pane).find('.save-order').fadeOut();

    $('#add-order').removeAttr('disabled');

    return true;
  };

  // Change to jQuery method
  var markPaneIncomplete = function(pane) {
    $(pane).removeClass('completed');
    $('#add-order').attr('disabled',true);
    return false;
  };

  // Change to jQuery method
  var markPaneInvalid = function(pane) {
    $(pane).addClass('invalid');
  };

  var validateOrderParams = function(event) {
    var currentPane = $(this).closest('#orders li');

    return allFieldsComplete(currentPane)?
      markPaneComplete(currentPane) : markPaneIncomplete(currentPane);
  };

  var addOrderHandler = function(event) {
    $('.active').removeClass('active');

    $('#add-order').attr('disabled', true);

    var newOrder = $('<li>').
      html($('#blank-order').html()).
      addClass('box active order').hide();

    newOrder.find('input, select').removeAttr('disabled');

    newOrder.find('.submission_project_name').autocomplete({
      source    : SCAPE.user_project_names,
      minLength : 3
    });

    newOrder.find('.save-order').click(projectSelectHandler);

    $('#blank-order').before(newOrder).fadeOut('fast',function(){
      newOrder.fadeIn();
    });
  };

  // Document Ready stuff...
  $(function(){
    $('#submission_template_id').change(templateChangeHandler);


    // $('.study_id').live('change', studySelectHandler);
    $('ul#orders').delegate('.study_id','change', studySelectHandler);


    $('#order-parameters .required').live('change',  validateOrderParams);

    $('#add-order').live('click', addOrderHandler);

  });

})(jQuery);

