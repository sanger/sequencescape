// Select 2 is a javascript library to provide advanced
// select dropdowns, including typing.
$(function () {
  $(".select2").select2({
    theme: "bootstrap4",
    minimumResultsForSearch: 10,
  });

  $("#tag_substitution_comment").select2({
    theme: "bootstrap4",
    tags: true,
  });
});
