require 'arp/format'
require 'arp/password_encryption'
require 'arp/tender'
require 'arp/utils'
require 'arp/globals'
require 'arp/aes_crypt'
require 'arp/redis'
require 'arp/hosts'

require 'digest'
require 'open3'

# Rails doesn't auto-load mailers outside of app/models, so do it
# explicitly here
require 'mailers/vm'

include Format
