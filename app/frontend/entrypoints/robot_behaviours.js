/**
 * Handles custom Bootstrap 4 dropdown submenu for robot driver file generation
 * behaviour selection. In the following example, Tecan 6 robot has multiple
 * generation behaviours (TecanV2 and TecanV3), so we create a submenu to list
 * these options. Lines 1 to 5 are standard Bootstrap 4 dropdown structure,
 * while lines 6 to 10 represent the custom submenu structure. When line 7 is
 * clicked, it toggles the visibility of 9 and 10. Note that some functionality
 * comes from Bootstrap's own JS, such as closing the dropdown when a
 * dropdown-item is clicked. Line 7 stops even propagation to prevent the main
 * dropdown from closing when toggling the submenu. There can be only one
 * submenu open at a time, and all submenus close when the main dropdown closes.
 * Lines 4, 5, 9, and 10 are links to download the respective robot driver
 * files; clicking them will close the entire dropdown.
 *
 * 1 dropdown
 * 2   dropdown-toggle [Download Robot File]
 * 3   dropdown-menu
 * 4      dropdown-item [Download HAMILTON STAR 6 File]
 * 5      dropdown-item [Download Artemis File]
 * 6      dropdown-submenu
 * 7          dropdown-toggle dropdown-item [Download Tecan 6 File]
 * 8          dropdown-menu
 * 9              dropdown-item [TecanV2]
 * 10             dropdown-item [TecanV3]
 *
 */
import $ from "jquery";
$(function () {
  $(".dropdown-submenu > button").on("click", function (e) {
    const submenuMenu = $(this).next(".dropdown-menu");
    const isOpen = submenuMenu.hasClass("show");
    // Close all submenus
    $(".dropdown-submenu .dropdown-menu").removeClass("show");
    // Only open if it was not already open
    if (!isOpen) {
      submenuMenu.addClass("show");
    }
    e.stopPropagation();
  });

  // Close all submenus when the main dropdown is closed
  $(".dropdown").on("hidden.bs.dropdown", function () {
    $(".dropdown-menu.show").removeClass("show");
  });
});
