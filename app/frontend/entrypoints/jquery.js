import jQuery from "jquery";
window.jQuery = jQuery;
window.$ = jQuery;
jQuery.ajaxSetup({
  headers: {
    "X-CSRF-Token": jQuery('meta[name="csrf-token"]').attr("content"),
  },
});
