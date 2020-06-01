/* ------------------------ */
/* NEW SERVICE CONFIGURATOR */
/* ------------------------ */

function populateIpAddresses(location_code) {
  $.ajax({
    dataType: "json",
    url: "/provisioning/ip_address",
    data: "location=" + location_code,
    success: function (data) {
      var hasIPs = false;
      var ips = data["ips"];

      var options = "<option value=''>" + data["caption"] + "</option>";

      $.each(ips, function (k, v) {
        hasIPs = true;
        options += '<option value="' + v["ip_address"] + '"';
        options += (v["assigned"] ? " disabled" : "") + ">";
        options += v["ip_address"];

        if (v["assigned"]) {
          options += " (" + v["assignment"] + ")";
        }

        options += "</option>";
      });

      if (hasIPs == false) {
        options +=
          "<option value='' disabled>No IPs Available in " +
          data["location"] +
          "</option>";
      }

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
        checkboxes += buildSSHKeyInputCheckbox(
          v["id"],
          v["name"],
          v["username"]
        );
      });

      var element = $("#ssh_key_selector");
      element.html(checkboxes);
      $("#add_ssh_key").removeClass("is-loading");
      insertSSHKeyCallbacks();
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
      $(this).removeClass("is-danger");
    });
  });
  resetAddSSHKeyButton();
}

function resetAddSSHKeyButton() {
  $("button#add_ssh_key").removeClass("is-loading");
}

function buildSSHKeyInputCheckbox(id, name, username) {
  var checkbox =
    "<label>" +
    "<input type='checkbox' name='ssh_keys' id='ssh_key_" +
    id +
    "' value='" +
    id +
    "'>Username: " +
    username +
    ", Key Label: " +
    name +
    "<span class='icon is-small is-danger ssh-key-delete' data-ssh-key-id='" +
    id +
    "'><i class='fas fa-times'></i></span>" +
    "</label>";

  return checkbox;
}

function insertSSHKeyDeleteCallbacks() {
  var els = $(".ssh-key-delete");
  els.off(); // Remove anything previously bound

  els.click(function () {
    var id = $(this).data("ssh-key-id");

    var checkbox = $("#ssh_key_" + id);
    checkbox.prop("checked", false);
    checkbox.parent().addClass("disabled");

    $.ajax({
      type: "DELETE",
      url: "/accounts/000/ssh_keys/" + id,
      success: function (response) {
        var element = $("#ssh_key_" + id);
        element.parent().remove();
      },
      error: function (response) {
        alert("Oops, something went wrong.");
      },
    });
  });
}

function insertSSHKeyClickCallbacks() {
  $("input[name=ssh_keys]").on("click", function (e) {
    SSHKeySelectorHeaderError(false);
  });
}

function insertSSHKeyCallbacks() {
  insertSSHKeyDeleteCallbacks();
  insertSSHKeyClickCallbacks();
}

function addNewSSHKey(id, name, username) {
  var checkbox = buildSSHKeyInputCheckbox(id, name, username);
  $("#ssh_key_selector").append(checkbox);
  $("#ssh_key_" + id).prop("checked", true);
  $("#ssh_key_" + id)
    .parent()
    .addClass("fade-in");
  insertSSHKeyCallbacks();
}

function errorHandlerSSHKeyDialog(errors) {
  if (errors.name) {
    $("#ssh_key_dialog_form_ssh_key_name").addClass("is-danger");
  } else {
    $("#ssh_key_dialog_form_ssh_key_name").removeClass("is-danger");
  }

  if (errors.key) {
    $("#ssh_key_dialog_form_ssh_key_key").addClass("is-danger");
  } else {
    $("#ssh_key_dialog_form_ssh_key_key").removeClass("is-danger");
  }

  resetAddSSHKeyButton();
}

function PlanSelectorHeaderError(state) {
  if (state == true) {
    $("select[name=plan]").addClass("has-text-danger");
    $("#plan_selector_header").addClass("has-text-danger error-bounce");
    $("#plan_selector_header_error").removeClass("is-hidden");
  } else {
    $("select[name=plan]").removeClass("has-text-danger");
    $("#plan_selector_header").removeClass(
      "has-text-danger error-bounce"
    );
    $("#plan_selector_header_error").addClass("is-hidden");
  }
}

function OSSelectorHeaderError(state) {
  if (state == true) {
    $("#os_selector_header").addClass("has-text-danger error-bounce");
    $("#os_selector_header_error").removeClass("is-hidden");
  } else {
    $("#os_selector_header").removeClass(
      "has-text-danger error-bounce"
    );
    $("#os_selector_header_error").addClass("is-hidden");
  }
}

function IPv4AddressSelectorHeaderError(state) {
  if (state == true) {
    $("#ipv4_address_selector").addClass("has-text-danger");
    $("#ipv4_address_selector_header").addClass(
      "has-text-danger error-bounce"
    );
    $("#ipv4_address_selector_header_error").removeClass("is-hidden");
  } else {
    $("#ipv4_address_selector").removeClass("has-text-danger");
    $("#ipv4_address_selector_header").removeClass(
      "has-text-danger error-bounce"
    );
    $("#ipv4_address_selector_header_error").addClass("is-hidden");
  }
}

function SSHKeySelectorHeaderError(state) {
  if (state == true) {
    $("#ssh_key_selector_header").addClass(
      "has-text-danger error-bounce"
    );
    $("#ssh_key_selector_header_error").removeClass("is-hidden");
    $("#ssh_key_selector_error_message").removeClass("is-hidden");
  } else {
    $("#ssh_key_selector_header").removeClass(
      "has-text-danger error-bounce"
    );
    $("#ssh_key_selector_header_error").addClass("is-hidden");
    $("#ssh_key_selector_error_message").addClass("is-hidden");
  }
}

$(function () {
  /* Change the IP address drop-down based on the chosen location */
  $("#new_vps_with_os input[name=location]").change(function () {
    if ($(this).is(":checked")) {
      $("#ipv4_address_selector").parent().addClass("is-loading");
      populateIpAddresses($(this).val());
      IPv4AddressSelectorHeaderError(false);
    }
  });

  // Let us add a new key on-the-fly
  $("#add_ssh_key").click(function (e) {
    $("#ssh_key_dialog").addClass("is-active");
    $("#ssh_key_dialog_form_ssh_key_key").focus();
    $("html").addClass("is-clipped");
    SSHKeySelectorHeaderError(false);

    e.preventDefault();
  });

  $("#ssh_key_dialog_form_cancel_button").click(function (e) {
    resetSSHKeyDialogForm();
  });

  $("#ssh_key_dialog_form").on("submit", function (e) {
    $("button#add_ssh_key").addClass("is-loading");

    $.ajax({
      type: "POST",
      url: this.action,
      data: $(this).serialize(),
      success: function (response) {
        var key = response["key"];

        closeModals();
        resetSSHKeyDialogForm();
        addNewSSHKey(key["id"], key["name"], key["username"]);
      },
      error: function (response) {
        errorHandlerSSHKeyDialog(response.responseJSON.errors);
      },
    });
    e.preventDefault();
  });

  $("#ssh_key_dialog_form_ssh_key_key").on("focusout", function (e) {
    var key = $(this).val();
    var label = labelFromPubKey(key);
    var username = usernameFromPubKey(key);

    var label_input = $("#ssh_key_dialog_form_ssh_key_name");
    var username_input = $("#ssh_key_dialog_form_ssh_key_username");

    if (label_input.val() == "") {
      label_input.val(label);
    }

    if (username_input.val() == "") {
      username_input.val(username);
    }
  });

  // ----------- //
  // Validations //
  // ----------- //

  var SSHKeySelectorIveBeenWarned = false;

  $("select[name=plan]").on("click", function (e) {
    PlanSelectorHeaderError(false);
  });
  $("input[name=os]").on("click", function (e) {
    OSSelectorHeaderError(false);
  });
  $("#ipv4_address_selector").on("click", function (e) {
    IPv4AddressSelectorHeaderError(false);
  });

  $("#new_service_configurator").on("submit", function (e) {
    var hasErrors = false;

    var element = $("select[name=plan]");
    if (element.val() == "") {
      PlanSelectorHeaderError(true);
      hasErrors = true;
    }

    var element = $("#ipv4_address_selector");
    if (element.val() == "") {
      IPv4AddressSelectorHeaderError(true);
      hasErrors = true;
    }

    var os_selected = $("input[name=os]:checked").val();
    if (os_selected == "" || os_selected == undefined) {
      OSSelectorHeaderError(true);
      hasErrors = true;
    }

    var ssh_keys_selected = $("input[name=ssh_keys]:checked").val();
    if (SSHKeySelectorIveBeenWarned == false) {
      if (ssh_keys_selected == "" || ssh_keys_selected == undefined) {
        SSHKeySelectorHeaderError(true);
        hasErrors = true;
        SSHKeySelectorIveBeenWarned = true;
      }
    }

    if (hasErrors) {
      e.preventDefault();
    }
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
