// Export jquery for some legacy scripts
import jQuery from "jquery";
window.jQuery = jQuery;
window.$ = jQuery;

jQuery.ajaxSetup({
  headers: {
    "X-CSRF-Token": jQuery('meta[name="csrf-token"]').attr("content"),
  },
});
