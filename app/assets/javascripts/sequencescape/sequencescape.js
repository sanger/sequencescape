(function($, undefined) {

// TODO: REMOVE THIS FILE WHEN CONFIRMED THERE ARE NO MORE DEPENDENCIES WITH IT

window.swap_filter = function () {
  if ($('#filter_by').value == "project") {
    $('#filter_project').show();
    $('#filter_group').hide();
  } else {
    $('#filter_project').hide();
    $('#filter_group').show();
  }
}

window.submit = function(ident) {
  $(ident).submit();
}

window.show_update_loader = function() {
  $('update_loader').style.display = 'inline';
}

window.hide_update_loader = function () {
  $('update_loader').style.display = 'none';
}

window.select_all = function(){
  var scope = this.dataset.scope || 'body';
  $(scope).find('input[type="checkbox"]:enabled').prop('checked', true);
}

window.deselect_all = function(){
  var scope = this.dataset.scope || 'body';
  $(scope).find('input[type="checkbox"]:enabled').prop('checked', false);
}

window.disable_cr_and_change_focus = function(event, current_field, next_field) {
  if (event.keyCode !=13 && event.keyCode !=10) { return true; }
  $(next_field).focus();
  return false;
}

var Behaviours = {
  assign_handlers: function() {
    /** Select_all and Deselect_all buttons event handling **/
    $(".select-all-behaviour").click(select_all);
    $(".deselect-all-behaviour").click(deselect_all);
  }
};

  $( document ).ready(function() {
    Behaviours.assign_handlers();
  });
})(jQuery);
