//This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
//Please refer to the LICENSE and README files for information on licensing and authorship of this file.
//Copyright (C) 2007-2011,2011 Genome Research Ltd.
document.observe('dom:loaded', function(){
	TableSorterFacade.setup();
  Behaviours.assign_handlers();
});

function swap_filter() {
	if ($('filter_by').value == "project") {
		$('filter_project').show();
		$('filter_group').hide();
	} else {
		$('filter_project').hide();
		$('filter_group').show();
	}
}

function submit(ident) {
	$(ident).submit();
}

function swap_tab(ident, related, tab_no) {
	$$('a.tab' + tab_no).each ( function(item) {
		item.className = "tab" + tab_no;
	});

	$(ident).className = "selected tab" + tab_no;

	$$('div.tab_content' + tab_no).each ( function(item) {
  		item.style.display = "none";
	});

	$(related).style.display = "block";
}

function show_update_loader() {
	$('update_loader').style.display = 'inline';
}

function hide_update_loader() {
	$('update_loader').style.display = 'none';
}

// Pipelines code
function reload_batch(){
  window.location.reload();
  new Effect.Highlight('requests_list');
}

function select_all(){
  var checkboxes = $$('input[type="checkbox"]');
  checkboxes.each(function(r){
    r.setValue(true);
  });
}

function deselect_all(){
  var checkboxes = $$('input[type="checkbox"]');
  checkboxes.each(function(r){
    r.setValue(false);
  });
}

function disable_cr_and_change_focus(event, current_field, next_field) {
	if (event.keyCode !=13) { return; }
  $(next_field).focus();
  return false;
}

var TableSorterFacade = {
  setup : function(){
    if( ! TableKit.Sortable.detectors.include('date-rfc822') ) {
      this._add_custom_sort_type();
    }
  },
  extend_table : function(element_or_id) {
    TableKit.load(element_or_id);
  },
  _add_custom_sort_type : function(){
    TableKit.Sortable.detectors.unshift('date-rfc822');
    TableKit.Sortable.addSortType(
      new TableKit.Sortable.Type('date-rfc822',{
        pattern: /^\s*\d{1,2}\s+(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)\s+\d{4}\s*$/i, //1 Jan 2010
        normal: function(v) {
          return new Date(v).valueOf()
        }
      })
    );
  }
}

var Behaviours = {
  assign_handlers: function() {
    var $ = jQuery;
    /** Select_all and Deselect_all buttons event handling **/
    $(".select-all-behaviour").click(select_all);
    $(".deselect-all-behaviour").click(deselect_all);
  }
};


