document.observe('dom:loaded', function(){
  // moved to here from elsewhere
	if ($('fbg')) {
		new Effect.Highlight('fbg');
	} else if ($('fbr')) {
		new Effect.Pulsate('fbr', {duration: 1, from: 0.4});
	}
	TableSorterFacade.setup();
});

function swap_group(link_ident, ident, key, elementType) {
	hide_all_except('div', 'group_content', ident, key);
	soften_all(elementType, 'grouped_item', key);
	$(link_ident).style.fontWeight = 'bold';
	$(link_ident).style.textDecoration = 'underline';
}

function hide_all(elementType, className, key) {
	$(key).select(elementType + "." + className).each (
	  function(element) {
  		element.hide();
  	}
	);
}

function default_state(key) {
	$('everything').show();
	soften_all('div', 'grouped_item', key);
	$('everything_link').style.fontWeight = 'bold';
}

function soften_all(elementType, className, key) {
	$(key).select(elementType + "." + className).each ( 
	  function(element) {
  		element.style.fontWeight = 'normal';
  		element.style.textDecoration = 'none';
  	}
  );
}

function hide_all_except(elementType, className, ident, key) {
	hide_all(elementType, className, key);
	$(ident).show();
}

function reload_table() {
	TableKit.load();
	TableKit.heads['project_list_table'] = null;
    TableKit.rows['project_list_table'] = null;
	TableKit.Sortable.init('project_list_table');
}

function toggle_rows(ident) {
	var row_class = "report_" + ident;
	$$("tr." + row_class).each ( function(element) {
		element.toggle();
	});
}

function update_values(ident) {
	descriptor = $('mixer_' + ident + '_key').value;
	new Ajax.Updater('mixer_' + ident + '_values', "/projects/update_values/0?mixer=" + ident + "&key=" + descriptor, { method:'GET', asynchronous:true, evalScripts:true, onLoading:show_update_loader, onComplete:hide_update_loader });  
}

function add_project_mixer() {
	mixer = increment_counter('mixer_count');
	new Ajax.Request("/projects/add_mixer/0?mixer=" + mixer, { method:'GET', asynchronous:true, evalScripts:true, onLoading:show_update_loader, onComplete:added_project_mixer });
}

function add_sample_mixer() {
	mixer = increment_counter('mixer_count');
    sample_family_id = $('sample_type_by').value;
	new Ajax.Request("/samples/add_mixer/0?mixer=" + mixer + "&sample_family_id=" + sample_family_id, { method:'GET', asynchronous:true, evalScripts:true, onLoading:show_update_loader, onComplete:added_sample_mixer });
}

function remove_mixer (ident) {
	mixer = decrement_counter('mixer_count');
	$("mixer_" + ident + "_div").remove();
}

function remove_all_mixers () {
	mixer = reset_counter('mixer_count');
	$('sample_mixer').innerHTML = "";
}

function added_project_mixer(response) {
	hide_update_loader();
	if (response.status == 200) {
		values = collect_values('filter_form');
		$('project_mixer').innerHTML = $('project_mixer').innerHTML + response.responseText;
		populate_values(values, 'filter_form');
	} else {
		alert("Error: " + response.responseText);
	}
}

function added_sample_mixer(response) {
	hide_update_loader();
	if (response.status == 200) {
		values = collect_values('filter_form');
		$('sample_mixer').innerHTML = $('sample_mixer').innerHTML + response.responseText;
		populate_values(values, 'filter_form');
	} else {
		alert("Error: " + response.responseText);
	}
}

function increment_counter(ident) {
	$(ident).value = parseInt($(ident).value, 10) + 1;
	return $(ident).value;
}

function decrement_counter(ident) {
	$(ident).value = parseInt($(ident).value, 10) - 1;
	return $(ident).value;
}

function reset_counter(ident) {
	$(ident).value = 0;
	return $(ident).value;
}


function add_comment(ident) {
	comment = $('project_comment_description_' + ident).value;
	if (comment != "") {
		new Ajax.Updater("project_annotations_" + ident, "/projects/"+ident+"/comments/add?comment=" + comment, { method:'GET', asynchronous:true, evalScripts:true });
		$('project_comment_description_' + ident).value = "";
	}
}

function remove_comment(ident, project) {
	new Ajax.Updater("project_annotations_" + project, "/projects/"+project+"/comments/destroy/" + ident , { method:'GET', asynchronous:true, evalScripts:true });  }

function toggle_comments(ident) {
	$$("div.comments_" + ident).each ( function(element) {
		element.toggle();
	});
	$('project_annotation_add_' + ident).toggle();
}

function toggle_annotation_links() {
	$$("div.annotations").each (
	  function(element) {
      element.toggle();
  	}
	);
}

var field_count = 1;
var displayed_field = "field_1";

function select_all_options(className) {
	$$("input." + className).each (
	  function(element) {
  		element.checked = 1;
  	}
	);
	
	$('select_all').value = "yes";
}

function select_none(className) {
	$$("input." + className).each (
	  function(element) {
  		element.checked = 0;
  	}
	);
	
	$('select_all').value = "no";
}

// Added by Constantine on 18th of April 09 - Start
function select_all_with_limit(limit){
  var checkboxes = $$('input[type="checkbox"]');
  var counter=0;
  reset_all_boxes();
  checkboxes.each(function(r){
    if(limit<=counter){
      throw $break;
    }else{
      r.checked=true;
      counter++;
      return;
    }
  });
}
function reset_all_boxes(){
  var checkboxes = $$('input[type="checkbox"]');
  checkboxes.each(function(r){
    r.checked=false;
  });
}

// End

function swap_filter() {
	if ($('filter_by').value == "project") {
		$('filter_project').show();
		$('filter_group').hide();
	} else {
		$('filter_project').hide();
		$('filter_group').show();
	}
}

function swap_time_selector() {
    if ($('interval_by').value == "all time") {
        $('month_selector').hide();
        $('week_selector').hide();
        $('filter_year').hide();
    } else if ($('interval_by').value == "month") {
        $('month_selector').show();
        $('week_selector').hide();
        $('filter_year').show();        
    } else if ($('interval_by').value == "week") {
        $('month_selector').hide();
        $('week_selector').show();
        $('filter_year').show();        
    }
}

function submit(ident) {
	$(ident).submit();
}

function set_and_submit(ident_to_set, value_to_set, ident_to_submit) {
	$(ident_to_set).value = value_to_set;
	submit(ident_to_submit);
}

function field_type_change(ident) {
	if ( $("field_" + ident + "_kind").value == "Selection") {
		$("field_" + ident + "_option_editor").show();
	} else {
	  $("field_" + ident + "_option_editor").hide();
	}
}

// Adding and removing virtual fields
function add_field() {
	increment_field_count();
	new Ajax.Request("/families/add_field/0?field=" + field_count, { method:'GET', asynchronous:true, evalScripts:true, onComplete:added });
}

function add_option(field) {
	count = $("field_" + field + "_option_count");
	count.value = parseInt(count.value, 10) + 1;
	new Ajax.Request("/families/add_option/0?field=" + field_count + "&option=" + count.value, { method:'GET', asynchronous:true, evalScripts:true, onComplete:added_option });
}

function added(response) {
	if (response.status == 200) {
		values = collect_values('family_form');
		hide_editors();
		$('field_editors').innerHTML = $('field_editors').innerHTML + response.responseText;
		populate_values(values, 'family_form');
		rebuild_list();
		displayed_field = "field_" + field_count;
		highlight_link();
	} else {
		alert('Problem adding virtual field');
	}
}

function added_option(response) {
	if (response.status == 200) {
		values = collect_values('family_form');
		$(displayed_field + '_options').innerHTML = $(displayed_field + '_options').innerHTML + response.responseText;
		populate_values(values, 'family_form');
	} else {
		alert('Problem adding option for selection');
	}
}

function highlight_link() {
	$$('a.field_link').each (
	  function(element) {
  		element.removeClassName("selected_link");
  	}
	);
	
	$(displayed_field + "_link").addClassName("selected_link");
}

function hide_editors() {
	$$('div.field_editor').each (
	  function(editor) {
  		editor.hide();
  	}
	);
}

function increment_field_count() {
	field_count = field_count + 1;
}

// Rebuild the field list, based on the available editors
function rebuild_list() {
	empty_list();
	
	$$('div.field_editor').each (
	  function(item) {
  		add_to_field_list(item);
  	}
	);
	
	highlight_link();
}

function empty_list() {
	$('field_list').childElements().each ( function(element) {
		element.remove();
	});
}

function add_to_field_list(item) {
	name_field = $(item.id + "_name");

	if (name_field.value == "") {
  	name_field.value = "Untitled";
	}

	value = name_field.value;
	link = new Element('a',
	  { href : 'javascript:void(0);', 
    	"class" : "field_link", 
    	id : item.id + "_link", 
    	onclick : "display_editor('" + item.id + "');" } ).update(value);
                    
	list_item = new Element('li').update(link);
	
	$('field_list').appendChild(list_item);
}

function display_editor(ident) {
	hide_editors();
	$(ident).show();
	displayed_field = ident;
	highlight_link();
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

function loading(ident) {
	$(ident).style.display = 'none';
	$(ident + "_loading").style.display = '';
}

function loaded(ident) {
	$(ident + "_loading").style.display = 'none';
	$(ident).style.display = '';
}

// Using the .innerHTML call to add additional descriptors in this way is not ideal. Some
// browsers will reset the values of the fields within the target element. Here we collect
// and repopulate the field values.

function collect_values(ident) {
	var field_values = new Array();
	for(i=0; i < $(ident).elements.length; i++) {
		field = $(ident).elements[i];
		if (field.type=="checkbox") {
			field_values[field.name] = field.checked;
		} else {
			field_values[field.name] = field.value;		  		}
	}
	return field_values;
}

function populate_values(values, ident) {
	for(i=0; i < $(ident).elements.length; i++) {
		field = $(ident).elements[i];
		if (values[field.name] != null) {
			if (field.type=="checkbox") {
				field.checked = values[field.name];
			} else {
				field.value = values[field.name];
			}
		}
	}
}

function show_update_loader() {
	$('update_loader').style.display = 'inline';
}

function hide_update_loader() {
	$('update_loader').style.display = 'none';
}

function show_update_loader_by_id(id) {
	$('update_loader' + id).style.display = 'inline';
}

function hide_update_loader_by_id(id) {
	$('update_loader' + id).style.display = 'none';
}


function show_updates() {
	$('updates').style.display = 'block';
}

function hide_updates() {
	$('updates').style.display = 'none';
}

function display_updates() {
	hide_update_loader();
	show_updates();
}

function select_reference() {
	kind = $('assembly_kind').value;
	new Ajax.Updater('assembly', '/projects/choice/' + kind, {asynchronous:true, evalScripts:true, onComplete:display_submit });
}

function display_submit() {
	$('submit').style.display = 'block';
}

function toggle_table(ident) {
	if ($(ident).style.display == 'none') {
		show_project_table(ident);
	} else {
		hide_project_table(ident);
	}
}

function hide_notice(ident) {
	$(ident).style.display = 'none';
}

function hide_project_table(ident) {
	$(ident).style.display = 'none';
	$(ident + "_link").innerHTML = "Expand";
}

function show_project_table(ident) {
	$(ident).style.display = 'table';
	$(ident + "_link").innerHTML = "Hide";
}

function update_template() {
	type = $('type').value;
	id = $(type + '_family_id').value;  	new Ajax.Request("/families/" + id, { method:'GET', asynchronous:true, evalScripts:true });
}

function add_to_display(ident) {
  // var element = group_id_for_ident(ident);
  set_style_for_class(displayed_settings[ident], 'none');
  // displayed_settings[ident] = (element);
  set_style_for_displayed_settings('block');
}

function remove_from_display(ident) {
  set_style_for_class(displayed_settings[ident], 'none');
  displayed_settings[ident] = '';
}

function set_style_for_displayed_settings(style) {
  for (var n = 0; n < displayed_settings.length; n++) {
    if (displayed_settings[n] != '') {
      set_style_for_class(displayed_settings[n], '');
    }
  }
}

function set_style_for_class(new_class,style) {
  var elements = getElementsByClass(new_class);
  for (var i = 0; i < elements.length; i++) {
    elements[i].style.display = style;
  }
}

function submit_form(form) {
	show_loading();
	new Ajax.Updater('projects', '/projects/filter', {asynchronous:true, evalScripts:true, parameters:Form.serialize(form), onComplete:hide_loading() });
}

function getElementsByClass(searchClass,node,tag) {
  var classElements = new Array();
  if ( node == null )
    node = document;
  if ( tag == null )
    tag = '*';
  var els = node.getElementsByTagName(tag);
  var elsLen = els.length;
  var pattern = new RegExp('(^|\\s)'+searchClass+'(\\s|$)');
  for (i = 0, j = 0; i < elsLen; i++) {
    if ( pattern.test(els[i].className) ) {
      classElements[j] = els[i];
      j++;
    }
  }
  return classElements;
}

function show_loading() {
	$('filter_loading').style.display = 'block';
}

function hide_loading() {
	$('filter_loading').style.display = 'none';
}

function display_many() {
	$('multiple').style.display = 'table';
}



function reloadPane(pane, src) {
  new Ajax.Updater(pane, src, {asynchronous:1, 
															evalScripts:true, 
															onLoading:function(request){
															  pane.innerHTML = '<img alt="Wait" src="/images/ajax-loader.gif" style="vertical-align:-3px" /> Loading...';
															},
															onComplete:function(request) { 
																TableKit.load();
												        TableKit.heads['project_list'] = null;
												        TableKit.rows['project_list'] = null;
												        TableKit.Sortable.init(pane);}});
}


// Pipelines code
function reload_batch(){
  window.location.reload();
  new Effect.Highlight('requests_list');
}

function check_request_count() {
  if ($('batch_item_limit'))  {
    var requests = $$('form#requests_to_batch_form input[type="checkbox"]:checked').length;
    var item_limit = $('batch_item_limit').value;
    var overrun = requests - (item_limit-1);
    if (requests > (item_limit-1)) {
      alert('Batch size is limited to ' + item_limit + ' libraries (including 1 control).  Please deselect ' + overrun + ' or more libraries before continuing');
      return false;
    }
    else {
      return true;
    }
  }
  else {
    return true;
  }
}

function check_grouped_request_count() {
  var requests = $$('form#assets_to_batch_form input[type="checkbox"]:checked');
  var num_selected_requests = 0;
  requests.each(function(r){
	  num_selected_requests = num_selected_requests + parseInt($(  r.id + "_size" ).value);
	})
	
  if ($("selection_count")) {
      $("selection_count").replace('<p id="selection_count">You have selected <strong>' + num_selected_requests + '</strong></p>');
  }
  return true;
}

function check_count_before_start(){
  var item_limit = $('batch_item_limit').value;
  var underrun = $('underrun').value;
  var mod = Math.abs(underrun);

  if ($('batch_item_limit')) {
    if (underrun > 0) {
      alert('Batch size is limited to ' + item_limit + '.  Please edit the batch and add ' + mod + ' or more libraries before continuing');
      return false;
    }

    else if (underrun < 0) {
      alert('Batch size is limited to ' + item_limit + '.  Please edit the batch and remove ' + mod + ' or more libraries before continuing');
      return false;
    }

    else if (underrun == 0) {
    return true;
    }
  }
  else {
    return true;
  }
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

function loading(ident) {
  $(ident).style.display = 'none';
  $(ident + "_loading").style.display = '';
}

function toggle_fragments(){
  if ($('fragments').style.display == 'none'){
    Element.show('fragments');
    $('toggle_fragments_link').innerHTML = 'Hide';
  } else{
    Element.hide('fragments');
    $('toggle_fragments_link').innerHTML = 'Expand';
  }
}

function show_list_loading() {
  $('list_loading').style.display = 'inline';
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

function update_qc_row(select_id, row_id) {
  var select = document.getElementById(select_id);
  var row = $(row_id);
  var new_state = "qc_"+select.value;

  row.className = row.className.replace(/qc_\S*/, new_state);
  return;
  row.className = row.className.replace(/\s*qc_\S*\s*/, "");
  //new Effect.Morph(row_id, { style : "background: #fff", duration: 1.0, transition: Effect.Transitions.reverse});
  new Effect.Morph(row_id, { style: new_state , duration: 0.15, transition: Effect.Transitions.sinoidal});
  return;
}

function enable_combobox(elementId,value) {
    element = $(elementId); 
    if (!value) { element[0].selected = true }
    element.disabled = !value;
    for (var i=0;i<element.length;i++) {
      element[i].disabled = !value;
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
