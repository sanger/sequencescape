import $ from "jquery";

const disable_cr_and_change_focus = function (event) {
  if (event.keyCode != 13 && event.keyCode != 10) {
    return true;
  }
  $(this.dataset.tabTarget).trigger("focus");
  return false;
};

const select_all = function () {
  var scope = this.dataset.scope || "body";
  // find all the enabled, unchecked checkboxes and select them
  // fire the change event on them, to allow other js code to pick up that they have changed
  $(scope).find('input[type="checkbox"]:enabled:not(:checked)').prop("checked", true).trigger("change");
};

const deselect_all = function () {
  var scope = this.dataset.scope || "body";
  // find all the enabled, checked checkboxes and deselect them
  // fire the change event on them, to allow other js code to pick up that they have changed
  $(scope).find('input[type="checkbox"]:enabled:checked').prop("checked", false).trigger("change");
};

$(function () {
  $(".select-all-behaviour").on("click", select_all);
  $(".deselect-all-behaviour").on("click", deselect_all);
  $("input[data-tab-target]").on("keypress", disable_cr_and_change_focus);
});
