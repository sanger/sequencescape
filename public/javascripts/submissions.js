// Submission workflow jQuery Plugin...
(function($,undefined){
  var methods = {
    init : function(options) {
      return this;
    },

    // Returns true if the input fields in a pane have a value
    allFieldsComplete : function(pane) {
      // This is not very pretty but it is IE safe...
      var validationResult = true;

      this.find('input').each(function(element){ 

        if (!$(this).val().match(/^\d+$/)){
          validationResult = false;
        }
      });

      return validationResult;
    },

    hasAssets : function() {
      if (this.find('.asset_group_id').val() ||
          this.find('.sample_names_text').val() ) {
        return true;
      } else {
        return false;
      }
    },

    currentPane : function() {
      return this.closest('#orders > li');
    },

    markPaneIncomplete : function() {
      this.removeClass('completed');

      // Move this to an initialised callback
      $('#add-order').attr('disabled',true);

      return this;
    },

    markPaneInvalid : function() {
      return this.addClass('invalid');
    },

    markPaneComplete : function() {
      this.addClass('completed').
        removeClass('invalid').
        find('input, select');

      // Move this to an initialised callback
      this.find('.save-order, .cancel-order').hide();

      // Move this to an initialised callback
      $('#add-order').removeAttr('disabled');

      return this;
    }
  };


  $.fn.submission = function(method) {
    if (methods[method]) {
      return methods[method].apply(this, Array.prototype.slice.call(arguments, 1));
    } else if (typeof method === 'Object' || !method) {
      return methods.init.apply(this, arguments);
    } else {
      return $.error('Method '+method+' does not exist on jQuery.submission');
    }
  };
})(jQuery);


// Submission page code...
(function($, undefined){
  // Name spacing stuff...
  if ( window.SCAPE === undefined) { window.SCAPE = {}; }

  if ( SCAPE.submission === undefined) { 
    SCAPE.submission = {
      order_params : {}
    };
  }


  var templateChangeHandler = function(event){
    var currentPane = $(event.target).submission('currentPane');

    delete SCAPE.submission.template_id;

    $('#order-parameters').slideUp(function(){
      $(this).html('');
      currentPane.submission('markPaneIncomplete');

      if ($(event.target).val()) {

        SCAPE.submission.template_id = $(event.target).val();

        // Load the parameters for the new order
        $.get(
          '/submissions/order_parameters',
          { submission: SCAPE.submission },
          function(data) {
            $('#order-parameters').html(data);

            currentPane.submission('allFieldsComplete')?
              currentPane.submission('markPaneComplete'):
              currentPane.submission('markPaneIncomplete');

            $('#order-parameters').slideDown();
          }
        );
        return true;
      }
    });
  };


  var studySelectHandler = function(event) {
  // This handler depends on the study template being set earlier in the wizard.
    var currentPane = $(event.target).submission('currentPane');

    currentPane.submission('markPaneIncomplete');

    SCAPE.submission.study_id = $(event.target).val();

    if ($(event.target).val().length > 0) {
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
    } else {
      // The study selector has been reset so fade out and reset the field.
      currentPane.find('.study-assets').fadeOut(function(){
        $(this).html("");
      });

    }

  };


  var saveOrderHandler = function(event) {
    var currentPane = $(this).submission('currentPane');
    // refactor this little lot!
    SCAPE.submission.project_name                 = currentPane.find('.submission_project_name').val();
    SCAPE.submission.asset_group_id               = currentPane.find('#submission_asset_group_id').val();
    SCAPE.submission.sample_names_text            = currentPane.find('#submission_sample_names_text').val();
    SCAPE.submission.plate_purpose_id             = currentPane.find('#submission_plate_purpose_id').val();
    SCAPE.submission.lanes_of_sequencing_required = currentPane.find('.lanes_of_sequencing').val();
    SCAPE.submission.comments                     = currentPane.find('#submission_comments').val();


    $.post(
      '/submissions',
      { submission : SCAPE.submission },
      function(data) {

        // Ugly hack to load the order_valid flag before the returned
        // html is displayed.
        // Got to go....
        var tempResult = $('<div>').html(data);

        if(SCAPE.submission.order_valid) {
          currentPane.fadeOut(function(){
            //                                        vvvvvvvvvv-- Ugly, ugly, ugly...
            currentPane.find('.project-details').html(tempResult.html());

            currentPane.
              detach().
              removeClass('active invalid').
              find('.asset-input-toggle').remove();

            currentPane.submission('markPaneComplete').
              find('input, select, textarea').not('.delete-order').
              attr('disabled',true);

            $('#order-controls').before(currentPane);
            currentPane.fadeIn();

            $('#submission_id').val(SCAPE.submission.id);
            $('#start-submission').removeAttr('disabled');

            $('.pane').not('#blank-order').addClass('active');

            // This temporarily limits the order to one per submission...
            $('#add-order').attr('disabled', true);
          });

        } else {
          currentPane.find('.project-details').html(data);
          currentPane.submission('markPaneInvalid');
        }
      }
    );

    // don't forget to stop the form submitting...
    return false;
  };


  var validateOrderParams = function(event) {
    var currentPane = $(event.target).submission('currentPane');

    return currentPane.submission('allFieldsComplete')?
      currentPane.submission('markPaneComplete') : currentPane.submission('markPaneIncomplete');
  };


  // Validate that an order has a Project, Study and some Assets.
  var validateOrder = function(event) {
    var currentPane = $(event.target).submission('currentPane');

    var studyId     = currentPane.find('.study_id').val();
    var projectName = currentPane.find('.submission_project_name').val();
    var hasAssets   = currentPane.submission('hasAssets');


    if (studyId && projectName && hasAssets) {
      currentPane.find('.save-order').removeAttr('disabled');
    } else {
      currentPane.find('.save-order').attr('disabled', true);
    }

  };


  var getParamName = function(param) {
    return $(param).attr('id').replace('submission_order_params_','');
  };

  var addOrderHandler = function(event) {
    // Loads this order's parameters into the SCAPE.submission object...
    $('#order-parameters').find('select, input').each(function(){
      SCAPE.submission.order_params[getParamName(this)] = $(this).val();
    });

    // Mask out the order template parameters so that they can't be
    // changed once an order has been added.
    $('#order-template').find('select, input').attr('disabled',true);


    $('.active').removeClass('active');

    // Stop the submission from being built until new the order is either
    // saved or cancelled...
    $('#start-submission').attr('disabled',true);

    $('#add-order').attr('disabled', true);

    var newOrder = $('<li>').
      html( $('#blank-order').html() ).
      addClass('pane active order').hide();

    // Remove the disable from the form inputs
    // but leave the save button disabled
    newOrder.find('input, select, textarea').
      css('opacity', 1).
      not('.save-order').
      removeAttr('disabled');


    // if this is not a sequencing order remove the lanes_of_sequencing_required stuff
    if (SCAPE.submission.is_a_sequencing_order === false) {
      newOrder.find('.lanes-of-sequencing').remove();
    }

    newOrder.find('.submission_project_name').autocomplete({
      source    : SCAPE.user_project_names,
      minLength : 3
    });


    $('#blank-order').before(newOrder);
    newOrder.slideDown();

  };

  var cancelOrderHandler = function(event) {
    var currentPane = $(event.target).submission('currentPane');

    currentPane.slideUp(function(){
      currentPane.remove();
      if ($('.order.completed').length === 0) {
        $('#order-template').
          addClass('active').
          find('select, input').
          removeAttr('disabled');
      }

      $('#add-order').removeAttr('disabled');
    });

    // don't forget to stop the form submitting...
    return false;
  };

  var deleteOrderHandler = function(event) {
    var currentPane = $(event.target).submission('currentPane');

     $.post(
       '/orders/' + currentPane.find('.order-id').val(),
       {
       _method : 'delete',
       id      : currentPane.find('.order-id').val()
       },
       function(response) {
         currentPane.slideUp(function(){
           currentPane.remove();
           $('#add-order').removeAttr('disabled');

           if ($('.order.completed').length === 0) {
             $('#order-template').
               addClass('active').
               find('select, input').
               removeAttr('disabled');

             $('#start-submission').attr('disabled', true);
           }
         });
       });

    // don't forget to stop the form submitting...
    return false;
  };

  // Toggle the asset selector panels.
  // TODO: replace this with a jQuery UI tabview.  Needs the order IDs
  // sorting out for that though....
  var assetSelectorToggle = function(event) {
    var currentAssetsPanel      = $(event.target).closest('.assets');

    var nextAssetPanel =
      currentAssetsPanel.siblings(':hidden').first();

    currentAssetsPanel.fadeOut(function(){
      nextAssetPanel.find('input, textarea, select').val('');
      nextAssetPanel.fadeIn();
    });
  };

  // Document Ready stuff...
  $(function() {
    // Initialise the #start-submission button.
    $('#start-submission').
      attr('disabled', true);

    // Initialise the template selector and attach a change handler to
    // it.
    $('#submission_template_id').
      val('Please select a template...').
      attr('selected', true).
      removeAttr('disabled').
      change(templateChangeHandler);

    // Validate the order-parameters
    $('#order-parameters .required').
      live('keypress',  validateOrderParams).
      live('blur',  validateOrderParams);

    $('#add-order').
      live('click', addOrderHandler);

    $('.submission_project_name').autocomplete({
      source    : SCAPE.user_project_names,
      minLength : 3,
      select : validateOrder
    });

    // NB.  There seems to being some odd behaviour related to the
    // autocompleter select callback fireing.  As a cludgy fix validation is
    // triggered on field keypresses as a supplimentry validation.
    $('ul#orders').
      delegate('li.order select, li.order input, li.order textarea', 'blur', validateOrder).
      delegate('.sample_names_text, li.order input', 'keypress', validateOrder).
      delegate('li.order select', 'change', validateOrder);

    // Most of the event handlers can be hung from the orders list...
    // NB. If we upgrade from jQuery 1.6.x to >= 1.7 then we may want to swap
    // out .delegate() to use the .on() function instead.
    $('ul#orders').
      delegate('.study_id',     'change', studySelectHandler).
      delegate('.cancel-order', 'click',  cancelOrderHandler).
      delegate('.save-order',   'click',  saveOrderHandler).
      delegate('.delete-order', 'click',  deleteOrderHandler).
      delegate('.assets a',     'click',  assetSelectorToggle);

  });

})(jQuery);

