// To see this message, add the following to the `<head>` section in your
// views/layouts/application.html.erb
//
//    <%= vite_client_tag %>
//    <%= vite_javascript_tag 'application' %>

// If using a TypeScript entrypoint file:
//     <%= vite_typescript_tag 'application' %>
//
// If you want to use .jsx or .tsx, add the extension:
//     <%= vite_javascript_tag 'application.jsx' %>

// Visit the guide for more information: https://vite-ruby.netlify.app/guide/rails

// Example: Load Rails libraries in Vite.
//
// import * as Turbo from '@hotwired/turbo'
// Turbo.start()
//
// import ActiveStorage from '@rails/activestorage'
// ActiveStorage.start()
//
// // Import all channels.
// const channels = import.meta.globEager('./**/*_channel.js')

// Example: Import a stylesheet in app/frontend/index.css
// import '~/index.css'

import Rails from "@rails/ujs";

try {
  Rails.start();
} catch {
  // Nothing
}
// Bootstrap
// We import the bundled version, as it automatically includes popper et al for us
// If we don't use the bundled version, we don't get automatic mounting of
// behaviour according to data attributes
import "bootstrap/dist/js/bootstrap.bundle.min.js";

import "../datatables";
import "../barcodeRendering";
import "../legacy";

// Export jquery for some legacy scripts
import jQuery from "jquery";
window.jQuery = jQuery;
window.$ = jQuery;

jQuery.ajaxSetup({
  headers: {
    "X-CSRF-Token": jQuery('meta[name="csrf-token"]').attr("content"),
  },
});
