//This file is part of SEQUENCESCAPE; it is distributed under the terms of GNU General Public License version 1 or later;
//Please refer to the LICENSE and README files for information on licensing and authorship of this file.
//Copyright (C) 2015,2016 Genome Research Ltd.
//This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
//Please refer to the LICENSE and README files for information on licensing and authorship of this file.
//Copyright (C) 2007-2011 Genome Research Ltd.
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

window.swap_tab = function(ident, related, tab_no) {
  // DEPRECATED hopefully
  $('a.tab' + tab_no).each ( function(pos, item) {
    item.className = "tab" + tab_no;
  });

  $(ident).className = "selected tab" + tab_no;

  $('div.tab_content' + tab_no).each ( function(pos, item) {
      item.style.display = "none";
  });

  $(related).style.display = "block";
}

window.show_update_loader = function() {
  $('update_loader').style.display = 'inline';
}

window.hide_update_loader = function () {
  $('update_loader').style.display = 'none';
}

// Pipelines code
window.reload_batch = function(){
  window.location.reload();
  new Effect.Highlight('requests_list');
}

window.select_all = function(){
  var checkboxes = $('input[type="checkbox"]');
  checkboxes.each(function(pos, r){
    if (!r.disabled) {
      $(r).prop('checked', true);
    };
  });
}

window.deselect_all = function(){
  var checkboxes = $('input[type="checkbox"]');
  checkboxes.each(function(pos, r){
    $(r).prop('checked', false);
  });
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
