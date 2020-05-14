$(function() {
  /* ------------------------ */
  /* NEW SERVICE CONFIGURATOR */
  /* ------------------------ */

  /* Change the IP address drop-down based on the chosen location */
  $('#new_vps_with_os input[name=location]').change(function() {
    if($(this).is(":checked")) {
      $.ajax({
        dataType: 'json',
        url: '/provisioning/ip_address',
        data: 'location=' + $(this).val(),
        success: function(data) {
          ips = data['ips']

          options = '<option>' + data['caption'] + '</option>'

          $.each(ips, function(k, v) {
            options += '<option' + (v['assigned'] ? ' disabled' : '') + '>'
            options += v['ip_address']


            if(v['assigned']) {
              console.log(v)
              options += ' (assigned to ' + v['assignment'] + ')'
            }

            options += '</option>'
          })

          $('#ipv4_address_selector').html(options)
        },
        error: function(data) {
          alert("Could not retrieve IP addresses.\nPlease try again later.")
        }
      })
    }
  })
});
