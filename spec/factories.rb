FactoryBot.define do
  sequence :login do |n|
    "foo#{n}"
  end

  sequence :email do |n|
    "foo#{n}@example.com"
  end

  factory :account do
    login
    email
    password 'password'
    password_confirmation 'password'
  end

  factory :service do
    account
    service_code
    billing_amount 5.00
  end

  factory :service_code do
    factory :service_code_for_ip_block do
      name 'IP_BLOCK'
    end
  end

  factory :resource do
    service
  end

  factory :location do
    name 'Los Angeles'
    code 'lax'
  end

  factory :ip_block do
    location
    cidr '10.0.0.0/30'
    vlan '999'
    after(:create) do |ip|
      ip.resource = create(:resource, assignable: ip)
    end

    trait :available do
      available true
    end
  end

  factory :vlan do
    location
    vlan 100
  end

  factory :virtual_machine do
    uuid '682950e4-4af8-11e0-8cea-001c25748b20'
    label 'foo'
    host  'kct01.arpnetworks.com'
    ram   1024
    storage 20
    after(:create) do |vm|
      vm.resource = create(:resource, assignable: vm)
    end
  end

  factory :bandwidth_quota do
    cacti_username 'johndoe'
    cacti_password 'peeword'
    cacti_local_graph_id 1000
    after(:create) do |bq|
      bq.resource = create(:resource, assignable: bq)
    end
  end

  factory :dns_domain do
    name '0.0.10.in-addr.arpa'
    type 'MASTER'
  end

  factory :dns_record do
    dns_domain
    name '2.0.0.10.in-addr.arpa'
    content 'example.com'
    after(:build) do |r|
      r.type = 'PTR'
    end

    factory :dns_record_with_ns_type do
      after(:build) do |r|
        r.type = 'NS'
      end
    end
  end

  factory :backup_quota do
    server 'backup01.cust.arpnetworks.com'
    username 'garry'
    group 'sftpusers'
    quota 20000000
    home_dir '/home/sftpusers/home/garry'
    chroot_dir '/home/sftpusers/home'
    notes ''
  end

  factory :credit_card do
    association :account
    display_number '1111'
    number 4111111111111111
    month '12'
    year '2036'
    first_name 'John'
    last_name 'Doe'
    billing_country_iso_3166 'US'
  end
end
