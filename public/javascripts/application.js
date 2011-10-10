document.observe('dom:loaded', function(){
	TableSorterFacade.setup();
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

function samples_are_selected() {
  var checkboxes = $$('input[type="checkbox"].sample_check');
  var selected = $$('input[type="checkbox"]:checked.sample_check');
  var found = false;
  if (selected.length > 0){
    found = true;
  }
  if (checkboxes.length == 0) {
    found = true;
  }
  return found;
}

function submit_stage() {
  if (samples_are_selected() == true) {
    $('stage_button').disabled = true;
    $('stage_links').style.display = 'none';
    $('stage_loading').style.display = 'inline';
    document.getElementById('stage_form').submit();

    // alert(form);
    // $('stage_form').submit();
  } else {
    alert('Please select one or more items.');
  }
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
