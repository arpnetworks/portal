document.addEventListener("keydown", function (event) {
  var e = event || window.event;
  if (e.keyCode === 27) {
    closeModals();
  }
});

function closeModals() {
  $(".is-active").each(function (index) {
    $(this).removeClass("is-active");
    $("html").removeClass("is-clipped");
  });
}

$(function () {
  $(".modal-button").click(function () {
    var target = $(this).data("target");
    $("html").addClass("is-clipped");
    $(target).addClass("is-active");
  });

  $(".modal-cancel").click(function (e) {
    e.preventDefault();

    var target = $(this).data("target");
    $("html").removeClass("is-clipped");
    $(target).removeClass("is-active");
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
