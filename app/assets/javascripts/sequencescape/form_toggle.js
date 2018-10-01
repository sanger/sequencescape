(function (window,$) {
  document.observe('dom:loaded', function() {
    $('form.submit_once').submit(function(){ $(this).children('.disable_on_submit').attr('disabled','disabled'); });
  })
})(window,jQuery)
