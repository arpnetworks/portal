Factory.define :account do |a|
  a.sequence(:login) { |n| "foo#{n}" }
  a.sequence(:email) { |n| "foo#{n}@example.com" }
  a.password 'password'
  a.password_confirmation { |a| a.password }
end

Factory.define :service do |s|
  s.association :account
  s.association :service_code
  s.billing_amount 5.00
end

Factory.define :service_code do |sc|
end

Factory.define :service_code_for_ip_block, :parent => :service_code do |sc|
  sc.name 'IP_BLOCK'
end

Factory.define :resource do |r|
  r.association :service
end

Factory.define :ip_block do |ip|
  ip.cidr '10.0.0.0/30'
  ip.vlan '999'
  ip.after_create do |ip|
    ip.resource = Factory.create(:resource, :assignable => ip)
  end
end

Factory.define :virtual_machine do |vm|
  vm.uuid '682950e4-4af8-11e0-8cea-001c25748b20'
  vm.label 'foo'
  vm.after_create do |vm|
    vm.resource = Factory.create(:resource, :assignable => vm)
  end
end

Factory.define :bandwidth_quota do |bq|
  bq.cacti_username 'johndoe'
  bq.cacti_password 'peeword'
  bq.cacti_local_graph_id 1000
  bq.after_create do |bq|
    bq.resource = Factory.create(:resource, :assignable => bq)
  end
end

Factory.define :dns_domain do |d|
  d.name '0.0.10.in-addr.arpa'
end

Factory.define :dns_record do |r|
  r.association :dns_domain
  r.name '2.0.0.10.in-addr.arpa'
  r.content 'example.com'
  r.after_build do |r|
    r.type = 'PTR'
  end
end

Factory.define :dns_record_with_ns_type, :class => DnsRecord do |r|
  r.association :dns_domain
  r.name '2.0.0.10.in-addr.arpa'
  r.content 'example.com'
  r.after_build do |r|
    r.type = 'NS'
  end
end

Factory.define :backup_quota do |bq|
  bq.server 'backup01.cust.arpnetworks.com'
  bq.username 'garry'
  bq.group 'sftpusers'
  bq.quota 20000000
  bq.home_dir '/home/sftpusers/home/garry'
  bq.chroot_dir '/home/sftpusers/home'
  bq.notes ''
end

Factory.define :credit_card do |cc|
  cc.association :account
  cc.display_number '1111'
  cc.number 4111111111111111
  cc.month '12'
  cc.year '2036'
  cc.first_name 'John'
  cc.last_name 'Doe'
  cc.billing_country_iso_3166 'US'
end
