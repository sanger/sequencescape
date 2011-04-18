var controller_name;
var model_name;

function field_change(ident) {
  $('field_selection_' + ident).style.display = ($('field_type_' + ident).value == 'Selection') ? 'block' : 'none';
}

function set_controller(name) {
	controller_name = name;
}

function set_model(name) {
	model_name = name;
}

function controller() {
	return "/" + controller_name;
}

function model() {
	return model_name;
}

function handleErrorResponse(response) {
  alert("There was a problem (HTTP Error Code: " + response.status + ")");
}

// When dealing with Ajax that updates forms you need to ensure that you maintain the values that
// were present before the innerHTML gets updated.  This is because the innerHTML is what is 
// present, not what is present when you substitute all of the values.
//
// NOTE: We have to maintain two separate maps (one from general INPUT field to value, and one
// from INPUT[type=checkbox] to its checked status, because of the way that Rails generates a 
// input[type=checkbox] and a input[type=hidden] for checkbox fields.
function maintainFormValues(form_id, callback) {
  var inputValues    = new Array();
  var checkboxValues = new Array();

  walkAllFormElements(form_id, function(field) {
    if (field.type == 'checkbox') {
      checkboxValues[ field.name ] = field.checked;
    } else {
      inputValues[ field.name ] = field.value;
    }
  });

  callback();

  walkAllFormElements(form_id, function(field) {
    if (field.type == 'checkbox') {
      field.checked = checkboxValues[ field.name ];
    } else if (inputValues[ field.name ] != null) {
      field.value = inputValues[ field.name ];
    }
  });
}

function walkAllFormElements(form_id, callback) {
  var formElement = $(form_id);
  if (formElement == null) { return; }
  for (i = 0; i < formElement.elements.length; ++i) {
    callback(formElement.elements[ i ]);
  }
}

function removeRow(type, identity) {
  decrement_counter('count', function() {
    row = $(type + '_' + identity);
    row.parentNode.removeChild(row);
  });
}

function increment_counter(ident, callback) {
  var counterElement    = $(ident);
  var currentCount      = parseInt(counterElement.value);
  currentCount         += 1;
  counterElement.value  = currentCount;
  callback(currentCount);
}

function decrement_counter(ident, callback) {
  var counterElement = $(ident);
  var currentCount   = parseInt(counterElement.value);
  if (currentCount > 1) {
    currentCount         -= 1;
    counterElement.value  = currentCount;
    callback(currentCount);
  }
}

function addDescriptor() {
  increment_counter('count', function(count) {
    url = controller() + "/new_field/" + count;
    new Ajax.Request(
      url, { 
        method:'GET', asynchronous:true, evalScripts:true, 
        onSuccess: function(response) { handleDescriptor(response, model() + '_form'); },
        onFailure: handleErrorResponse
      }
    );
  });
}

function addAsset(family) {
  increment_counter('count', function(count) {
    $('descriptors').style.display = 'table';
    url = controller() + "/new/" + count + "?family=" + family;
    new Ajax.Request(
      url, {
        method:'GET', asynchronous:true, evalScripts:true, 
        onSuccess: function(response) { handleDescriptor(response, model() + '_form'); },
        onFailure: handleErrorResponse
      }
    )
  });
}

function addOption(field, controller, model) {
  increment_counter('option_count_' + field, function(new_ident) {
    url = "/" + controller + "/new_option/" + field + "?option=" + new_ident;
    new Ajax.Request(
      url, { 
        method:'GET', asynchronous:true, evalScripts:true, 
        onSuccess: function(response) { 
          maintainFormValues(model + '_form', function() {
            optionsField = $('field_options_' + field);
            optionsField.innerHTML = optionsField.innerHTML + response.responseText;
          });
        },
        onFailure: handleErrorResponse
      }
    );
  });
}

function removeDescriptor(ident) { removeRow('descriptor', ident); }
function removeAsset(ident)      { removeRow('asset', ident);      }

function removeOption(field, ident) {
  decrement_counter('option_count_' + field, function() {
    row = $('field_' + field + "_option_" + ident);
    row.parentNode.removeChild(row);
  });
}

// This function is called when the addAsset or addDescriptor Ajax code completes.  It copies
// the current values from the form, updates 'descriptors' element with the response text, and
// then repopulates the form fields.  It does this because, apparently, some browsers reset
// their form contents.
function handleDescriptor(response, form_id) {
  maintainFormValues(form_id, function() {
    descriptorsElement = $('descriptors');
    descriptorsElement.innerHTML = descriptorsElement.innerHTML + response.responseText;
  });
}
