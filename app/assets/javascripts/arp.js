$(function() {
  /* ------------------------ */
  /* NEW SERVICE CONFIGURATOR */
  /* ------------------------ */

  /* Change the IP address drop-down based on the chosen location */
  $('#new_vps_with_os input[name=location]').change(function() {
    if($(this).is(":checked")) {
      $.ajax({
        dataType: 'json',
        url: '/accounts/ip_addresses',
        data: 'location=' + $(this).val(),
        success: function(data) {
          var s = '';
          console.log(data)
          $.each(data, function(k, v) {
            s += "IP: " + v['ip_address'] + "\n" +
                 "Assigned: " + v['assigned'] + "\n" +
                 "Assignment: " + v['assignment']
          })

          alert(s)
        },
        error: function(data) {
          alert("Could not retrieve IP addresses.\nPlease try again later.")
        }
      })
    }
  })
});
