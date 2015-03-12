//This file is part of SEQUENCESCAPE is distributed under the terms of GNU General Public License version 1 or later;
//Please refer to the LICENSE and README files for information on licensing and authorship of this file.
//Copyright (C) 2015 Genome Research Ltd.

(function ($, undefined) {
  $(document).ready(function() {

    var clashChecker, attach, detach, moveTo, preventMatchingAssetPooling;

    preventMatchingAssetPooling = true;

    clashChecker = function(children,candidate_jq,errorReporter) {
      var candidate = candidate_jq.get(0)
      for (var i = 0; i < children.length; i+=1) {
        var child = children.get(i)
        if (
        (candidate.dataset.requestId !== (child.dataset.requestId)) && // the candidate becomes a child of the target before it is tested. We avoid it matching itself
        (preventMatchingAssetPooling || (candidate.dataset.assetId !== child.dataset.assetId))// if preventMatchingAssetPooling Only perform checks if assets don't match
        ) {
          if(candidate.dataset.tagIndex === '-' || child.dataset.tagIndex === '-') { errorReporter('Can not multiplex untagged samples'); return true; } // We can't mix untagged with anything
          if(candidate.dataset.tagIndex === child.dataset.tagIndex ) { errorReporter('Can not multiplex matching tags'); return true; } // We can't mix matching tags
          if(candidate.title !== child.title) { errorReporter('Tubes have incompatible request options (eg. Movie Length)'); return true;} // We can't mix incompatible tubes

        }
      };

      return false;
    }

    reportError = function(error) { $('#error_messages').show(100).text(error) };
    doNothing = function(){};

    attach = function(tube,target) { document.getElementById('locations_for_'+tube.dataset.requestId).value=target.dataset.wellLocation };
    detach = function(tube) { document.getElementById('locations_for_'+tube.dataset.requestId).value='' };

    // moveTo bypasses the receive and remove checks.
    moveTo = function(tube,target) { $(target).append(tube); attach(tube,target);};
    reset = function(tube) { $('#tube_source').append(tube); detach(tube);};

    well_array = [
      "A1", "B1", "C1", "D1", "E1", "F1", "G1", "H1",
      "A2", "B2", "C2", "D2", "E2", "F2", "G2", "H2",
      "A3", "B3", "C3", "D3", "E3", "F3", "G3", "H3",
      "A4", "B4", "C4", "D4", "E4", "F4", "G4", "H4",
      "A5", "B5", "C5", "D5", "E5", "F5", "G5", "H5",
      "A6", "B6", "C6", "D6", "E6", "F6", "G6", "H6",
      "A7", "B7", "C7", "D7", "E7", "F7", "G7", "H7",
      "A8", "B8", "C8", "D8", "E8", "F8", "G8", "H8",
      "A9", "B9", "C9", "D9", "E9", "F9", "G9", "H9",
      "A10", "B10", "C10", "D10", "E10", "F10", "G10", "H10",
      "A11", "B11", "C11", "D11", "E11", "F11", "G11", "H11",
      "A12", "B12", "C12", "D12", "E12", "F12", "G12", "H12"
    ];

    $('.tube_source').sortable({
      cancel:'p',
      connectWith: '.tube_receiver'
    }).disableSelection();

    $('.pac_well').sortable({
      cancel:'p',
      connectWith: '.tube_receiver',
      receive: function( event,ui ) {
        if (clashChecker($(this).children('.library_tube'),ui.item,reportError)) {
          $(ui.sender).sortable('cancel');
        } else {
          attach(ui.item.get(0),this)
        }
      },
      remove: function(event,ui) {
        detach(ui.item.get(0));
      }
    }).disableSelection();

    // Button actions
    $('#one_cell_per_well').bind('click',function(){
      var unsorted_tubes, offset = 0;

      unsorted_tubes = $('.tube_source .library_tube');

      for (var i = 0; i < unsorted_tubes.length ; i+=1) {
        var next_well;

        // Find the first empty well
        while ((next_well = document.getElementById('well_'+well_array[i+offset])) && next_well.childElementCount > 0) {
          offset += 1;
        }

        if (next_well===null) { return false; } // We've run out of space.

        moveTo(unsorted_tubes[i],next_well);
      }
    });

    $('#pool_matching').bind('click',function(){
      var destination = {}, well_index = 0, unsorted_tubes;

      unsorted_tubes = $('.tube_source .library_tube');

      for (var i = 0; i < unsorted_tubes.length ; i+=1) {
        var next_well;

        if (destination[unsorted_tubes[i].dataset.assetId]) {
          next_well = destination[unsorted_tubes[i].dataset.assetId]
        } else {
          // Find the first empty well
          while ((next_well = document.getElementById('well_'+well_array[well_index])) && next_well.childElementCount > 0) {
            well_index += 1;
          }
          destination[unsorted_tubes[i].dataset.assetId] = next_well;
        }
        if (next_well) { moveTo(unsorted_tubes[i],next_well); }
      }
    });

    $('#smart_multiplexing').bind('click',function(){
      var well_index = 0, unsorted_tubes;

      unsorted_tubes = $('.tube_source .library_tube');

      // Find first empty well
      while ((next_well = document.getElementById('well_'+well_array[well_index])) && next_well.childElementCount > 0) {
        well_index += 1;
      }
      for (var i = 0; i < unsorted_tubes.length ; i+=1) {

        if (clashChecker($(next_well).children(),$(unsorted_tubes.get(i)),doNothing)) {
          well_index+= 1;
          while ((next_well = document.getElementById('well_'+well_array[well_index])) && next_well.childElementCount > 0) {
            well_index += 1;
          }
        }

        if (next_well) { moveTo(unsorted_tubes.get(i),next_well); }
      }
    });

    $('#clear_plate').bind('click',function(){
      $('.library_tube').each(function(){ reset(this); })
    });


  })
})(jQuery)
