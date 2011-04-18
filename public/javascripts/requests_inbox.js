var Inbox = {
    target_div: "form#requests_to_batch_form",
//assets_to_batch_form

    setup_dynamic_interface: function() {
      //Inbox.insert_selection_controls("selection_helpers");
      Inbox.insert_grouping_controls();
      Inbox.update_selected_requests();
    },
    insert_selection_controls: function(replaced_id) {
      var controls = new Element('fieldset');
      controls.appendChild(new Element('legend').update("Selection helpers"));

      if (Inbox.batch_has_limit()) {
        controls.appendChild(new Element('input', {
          'type': 'button',
          'value': 'Select up to limit',
          'onclick': 'select_requests_up_to_limit(Inbox.target_div)'}));
        controls.appendChild(new Element('input', {
          'type': 'button',
          'value': 'Deselect all',
          'onclick': 'deselect_all_requests()'}));
      } else {
        controls.appendChild(new Element('input', {
          'type': 'button',
          'value': 'Select all',
          'onclick': 'select_all_requests()'}));
        controls.appendChild(new Element('input', {
          'type': 'button',
          'value': 'Deselect all',
          'onclick': 'deselect_all_requests()'}));
      }
      $(replaced_id).replace(controls);
    },
    insert_grouping_controls: function() {
      $$('div.request_group').each(function(group_div){
        var group_id = /group_(\d+)/.exec(group_div.id)[1]
        var controls = new Element('fieldset');
        controls.appendChild(new Element('legend').update("Selection helpers"));
        controls.appendChild(new Element('input', {
          'type': 'button',
          'value': 'Select this group',
          'onclick': 'select_requests_by_grouping("#group_'+group_id+'")'}));
        controls.appendChild(new Element('input', {
          'type': 'button',
          'value': 'Deselect this group',
          'onclick': 'deselect_requests_by_grouping("#group_'+group_id+'")'}));
        // Small issue. Selected boxes are cleared on refesh with the following line and variants.
        group_div.down().insert({after: controls});
      });
    },
    check_request_count: function() {
        if (Inbox.batch_has_limit()) {
            var requests = Inbox.number_of_selected_requests();
            var item_limit = Inbox.batch_limit();
            var overrun = requests - (item_limit);
            if (requests > (item_limit)) {
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
    },
    update_selected_requests: function() {
        Inbox.update_number_of_selected_requests()
        Inbox.highlight_selected_rows();
        Inbox.check_request_count();
    },
    highlight_selected_rows: function() {
        $$('input[type="checkbox"]').each(function(n) {
            if (n.checked == true) {
                n.up().up().addClassName("selected");
            } else {
                n.up().up().removeClassName("selected");
            }
        });
    },
    update_number_of_selected_requests: function() {
      if ($("selection_count")) {
          var selection_count = Inbox.number_of_selected_requests();
          $("selection_count").replace('<p id="selection_count">You have selected <strong>' + selection_count + '</strong></p>');
      }
    },
    number_of_selected_requests: function() {
      return Inbox.selected_requests(Inbox.target_div).length;
    },
    requests: function() {
      return $$(Inbox.target_div + ' input[type="checkbox"]');
    },
    selected_requests: function() {
      return $$(Inbox.target_div + ' input[type="checkbox"]:checked');
    },
    grouped_requests: function(grouping) {
      return $$(grouping + ' input[type="checkbox"]');
    },
    batch_has_limit: function() {
      // This could be more robust
      return $('batch_item_limit') ? true : false;
    },
    batch_limit: function() {
      // The -1 is for the control lane. This needs to be dynamically set based on Pipeline
      return $('batch_item_limit').value - 1;
    }
}

function select_requests_up_to_limit(requests_wrapper) {
    var request_collection = Inbox.requests(requests_wrapper);
    for (var index = 0, len = request_collection.length; index < len; ++index) {
        var item = request_collection[index];
        if (Inbox.number_of_selected_requests(requests_wrapper) < Inbox.batch_limit()) {
            item.setValue(true);
        } else {
            break;
        }
    }
    Inbox.update_selected_requests();
    return request_collection;
}

function deselect_all_requests() {
    deselect_all();
    Inbox.update_selected_requests();
}

function select_all_requests() {
    select_all();
    Inbox.update_selected_requests();
}

function select_requests_by_grouping(grouping) {
    Inbox.grouped_requests(grouping).each(function(request) {
        request.setValue(true);
    });
    Inbox.update_selected_requests();
}

function deselect_requests_by_grouping(grouping) {
    Inbox.grouped_requests(grouping).each(function(request) {
        request.setValue(false);
    });
    Inbox.update_selected_requests();
}
