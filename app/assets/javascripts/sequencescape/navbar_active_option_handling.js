(function () {
  var attachEvents = function () {
    $("header nav ul.nav li")
      .filter(function (pos, n) {
        if (window.location.href.match($("a", n).attr("href")) !== null) {
          return true;
        }
      })
      .first()
      .addClass("active");
  };
  $(document).ready(attachEvents);
})();
