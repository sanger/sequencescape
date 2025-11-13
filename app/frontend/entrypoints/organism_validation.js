/*====================================================================
 *  Author: Tony Cox (avc@sanger.ac.uk)
 *  Copyright (c) 2009: Genome Research Ltd.
 * This is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.
 * or see the on-line version at http://www.gnu.org/copyleft/gpl.txt
 *====================================================================
 * (c) Tony Cox (Sanger Institute, UK) avc@sanger.ac.uk
 *
 * Description: Provides interface for monitoring data in the Sanger
 * Illumina production pipeline
 *
 * Exported functions: None
 * HISTORY:
 *====================================================================
 */

const $ = window.jQuery;

$(function () {
  // Any validate_organism control needs to be setup to update the 'common name' and the 'taxon ID' fields.
  // It is assumed that the 'common name' and 'taxon ID' fields are paired in order: in other words, the
  // first 'common name' field goes with the first 'taxon ID' field.  If this is not true then you should
  // write your own method and call validateSingleOrganism yourself.
  $(".validate_organism").each(function (pos, control) {
    $(control).on("click", function (event) {
      event.preventDefault();
      var common_names = $('input[data-organism="common_name"]');
      var taxon_ids = $('input[data-organism="taxon_id"]');

      common_names.each(function (index, common_name) {
        validateOrganism(common_name, taxon_ids[index]);
      });
    });
  });
});

const highlight_field = function (state, field) {
  if (state == "good") {
    $(field).css("background-color", "#ffff99").animate({ backgroundColor: "#ffffff" }, 1500);
    //Element.highlight(field, { startcolor: '#ffff99', endcolor: '#ffffff', restorecolor: '#ffffff'});
  } else if (state == "bad") {
    $(field).css("background-color", "#A80000").animate({ backgroundColor: "#ff6666" }, 1500);
    //Element.highlight(field, { startcolor: '#A80000', endcolor: '#ffffff', restorecolor: '#ff6666'});
  }
};

const ajaxXMLRequest = function (url, field, callbacks) {
  var xmlSelect = function (element, name) {
    let elements = $(name, element);
    if (elements.length == 0) {
      return undefined;
    }
    return elements[0].text || elements[0].textContent || undefined;
  };

  $.ajax(url, {
    headers: { Accept: "application/xml,text/xml" },
    success: function (response) {
      let value = xmlSelect(response.responseXML, field);
      if (value == undefined) {
        callbacks.unfound();
      } else {
        callbacks.found(value);
      }
    },
    error: function () {
      callbacks.unfound();
    },
    timeout: 5000,
  });
};

const validateOrganism = function (common_name_field, taxon_id_field) {
  // Empty fields can be ignored
  if (common_name_field.value == "" || common_name_field.value == undefined) {
    return;
  }

  // Lookup the real 'common name' and 'taxon ID' based on the common name entered.  This involves
  // two Ajax calls: one for the original common name to 'taxon ID', the other from the 'taxon ID'
  // to the real 'common name'.  Obviously these need to be performed sequentially.
  ajaxXMLRequest("/taxa?term=" + common_name_field.value, "Id", {
    found: function (taxon_id) {
      ajaxXMLRequest("/taxa/" + taxon_id, "ScientificName", {
        found: function (scientific_name) {
          if (common_name_field.value != scientific_name) {
            common_name_field.value = scientific_name;
            highlight_field("good", common_name_field);
          }
          if (taxon_id_field.value != taxon_id) {
            taxon_id_field.value = taxon_id;
            highlight_field("good", taxon_id_field);
          }
        },

        unfound: function () {
          highlight_field("bad", common_name_field);
          highlight_field("bad", taxon_id_field);
        },
      });
    },

    unfound: function () {
      highlight_field("bad", common_name_field);
      highlight_field("bad", taxon_id_field);
    },
  });
};
