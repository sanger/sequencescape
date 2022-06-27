// Select 2 is a javascript library to provide advanced
// select dropdowns, including typing.

import $ from "jquery";

import select2 from "select2";
import "select2/dist/css/select2.css";
import "@ttskch/select2-bootstrap4-theme/dist/select2-bootstrap4.min.css";

select2();

$(() => {
  $(".select2").select2({
    theme: "bootstrap4",
    minimumResultsForSearch: 10,
  });

  $("#tag_substitution_comment").select2({
    theme: "bootstrap4",
    tags: true,
  });
});
