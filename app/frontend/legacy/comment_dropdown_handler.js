// Sets up a drop down animation for show and hide comment links
//
// Binds to: DOM elements with the class .show-comment (Show)
//           DOM elements with the class .hide-comment (Hide)
//
// Will use the following data attributes
// data-comment-field: A JQuery identifier (eg. #id or .class) for the DOM element
//                     to show/hide
//
// Dependent on: jquery
import $ from "jquery";

const attachEvents = function () {
  $(".show-comment").on("click", function () {
    $(this.dataset.commentField).slideDown();
  });
  $(".hide-comment").on("click", function () {
    $(this.dataset.commentField).slideUp();
  });
};

$(attachEvents);
