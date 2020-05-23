/* ------------------------ */
/* NEW SERVICE CONFIGURATOR */
/* ------------------------ */

function populateIpAddresses(location_code) {
  $.ajax({
    dataType: "json",
    url: "/provisioning/ip_address",
    data: "location=" + location_code,
    success: function (data) {
      var ips = data["ips"];

      var options = "<option>" + data["caption"] + "</option>";

      $.each(ips, function (k, v) {
        options += '<option value="' + v["ip_address"] + '"';
        options += (v["assigned"] ? " disabled" : "") + ">";
        options += v["ip_address"];

        if (v["assigned"]) {
          options += " (" + v["assignment"] + ")";
        }

        options += "</option>";
      });

      var element = $("#ipv4_address_selector");
      element.html(options);
      element.parent().removeClass("is-loading");
    },
    error: function (data) {
      alert(
        "Could not retrieve IP addresses.\nPlease try again later."
      );
    },
  });
}

function populateSSHKeys(account_id) {
  $.ajax({
    dataType: "json",
    url: "/accounts/" + account_id + "/ssh_keys",
    success: function (data) {
      showme = data;
      var checkboxes = "";

      $.each(data, function (k, v) {
        checkboxes += buildSSHKeyInputCheckbox(v["id"], v["name"]);
      });

      var element = $("#ssh_keys_selector");
      element.html(checkboxes);
      $("#add_ssh_key").removeClass("is-loading");
    },
    error: function (data) {
      alert("Could not retrieve SSH keys.\nPlease try again later.");
    },
  });
}

function resetSSHKeyDialogForm() {
  $.each(["input", "textarea"], function (index, element) {
    $("#ssh_key_dialog_form " + element).each(function (index) {
      $(this).val("");
    });
  });
}

function buildSSHKeyInputCheckbox(id, name) {
  var checkbox =
    "<label>" +
    "<input type='checkbox' name='ssh_keys' id='ssh_key_" +
    id +
    "' value='" +
    id +
    "'>" +
    name +
    "</label>";

  return checkbox;
}

function addNewSSHKey(id, name) {
  var checkbox = buildSSHKeyInputCheckbox(id, name);
  $("#ssh_keys_selector").append(checkbox);
  $("#ssh_key_" + id).prop("checked", true);
}

$(function () {
  /* Change the IP address drop-down based on the chosen location */
  $("#new_vps_with_os input[name=location]").change(function () {
    if ($(this).is(":checked")) {
      $("#ipv4_address_selector").parent().addClass("is-loading");
      populateIpAddresses($(this).val());
    }
  });

  // Let us add a new key on-the-fly
  $("#add_ssh_key").click(function (e) {
    $("#ssh_key_dialog").addClass("is-active");
    $("html").addClass("is-clipped");

    // For when it was a checkbox
    // $(this).children("input").prop("checked", false);

    e.preventDefault();
  });

  $("#ssh_key_dialog_form").on("submit", function (e) {
    $.ajax({
      type: "POST",
      url: this.action,
      data: $(this).serialize(),
      success: function (response) {
        var key = response["key"];

        closeModals();
        resetSSHKeyDialogForm();
        addNewSSHKey(key["id"], key["name"]);
      },
      error: function (response) {
        alert(response["errors"]);
      },
    });
    e.preventDefault();
  });

  // ---------- //
  // Navigation //
  // ---------- //

  // Check for click events on the navbar burger icon
  $(".navbar-burger").click(function () {
    // Toggle the "is-active" class on both the "navbar-burger" and the "navbar-menu"
    $(".navbar-burger").toggleClass("is-active");
    $(".navbar-menu").toggleClass("is-active");
  });
});
