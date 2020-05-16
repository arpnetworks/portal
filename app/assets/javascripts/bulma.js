document.addEventListener("keydown", function (event) {
  var e = event || window.event;
  if (e.keyCode === 27) {
    $(".modal-close").parent().removeClass("is-active");
  }
});

$(function () {
  $(".modal-button").click(function () {
    var target = $(this).data("target");
    $("html").addClass("is-clipped");
    $(target).addClass("is-active");
  });

  $.each([".modal-close", ".modal-background"], function (
    index,
    element
  ) {
    $(element).click(function () {
      $("html").removeClass("is-clipped");
      $(this).parent().removeClass("is-active");
    });
  });
});
