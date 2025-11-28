/**
 * This module enables tab navigation in a Rails views to be reflected in the URL anchor (hash).
 * - Clicking a tab updates the URL anchor to the tab name.
 * - Reloading or sharing the page with a hash will automatically open the correct tab.
 *
 * Usage::
 * 1. In your ERB view or partial with tab navigation, add at the bottom:
 *      <%= vite_javascript_tag 'tab_anchor' %>
 *
 * 2. Ensure each tab link:
 *    - Has an id of the form "tab-link-<tab_name>"
 *    - Has an href ending with "#<tab_name>"
 *    Example:
 *      <%= link_to "Tab Name",
 *                  some_path + "##{tab_name}",
 *                  id: "tab-link-#{tab_name}",
 *                  class: "nav-link" %>
 */

document.addEventListener("DOMContentLoaded", function () {
  // On page load, activate the tab from the hash if present
  var hash = window.location.hash;
  if (hash.length > 1) {
    var tabKey = hash.substring(1); // Remove the '#' prefix
    var tabLink = document.querySelector('a[id="tab-link-' + tabKey + '"]');
    if (tabLink) {
      tabLink.click();
    }
  }

  // When a tab is clicked, update the hash to just the tab name
  document.querySelectorAll(".nav-link").forEach(function (link) {
    link.addEventListener("click", function () {
      var id = this.id.replace("tab-link-", "");
      window.location.hash = id;
    });
  });
});
