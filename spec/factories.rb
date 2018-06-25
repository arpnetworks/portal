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

    factory :account_admin do
      login 'admin'
      password 'mysecret'
      password_confirmation 'mysecret'
    end

    factory :account_user do
      login 'user'
      password 'mysecret'
      password_confirmation 'mysecret'
    end
  end

  factory :service do
    account
    service_code
    billing_amount 5.00

    trait :deleted do
      deleted_at '01/01/1970'
    end
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

    sequence :code do |n|
      "lax-#{n}"
    end
  end

  factory :ip_block do
    location
    cidr '10.0.0.0/30'
    vlan '100'
    after(:create) do |ip|
      ip.resource = create(:resource, assignable: ip)
    end

    trait :available do
      available true
    end

    factory :ip_block_super do
      cidr '208.79.88.0/21'
      vlan '102'
    end

    factory :ip_block_smaller do
      cidr '208.79.88.0/24'
      vlan '105'
    end
  end

  factory :vlan do
    location
    vlan 100
  end

  factory :virtual_machine do
    sequence :uuid do |n|
      "682950e4-4af8-11e0-8cea-001c25748b#{n}"
    end
    sequence :label do |n|
      "foo#{n}"
    end
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
    type 'MASTER'

    trait :the_10_block do
      name '0.0.10.in-addr.arpa'
    end
    trait :the_192_block do
      name '0.168.192.in-addr.arpa'
    end
    trait :the_ipv6_block do
      name '8.f.2.f.7.0.6.2.ip6.arpa'
    end
  end

  factory :dns_record do
    # association :dns_domain, :the_10_block
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

    # We need to do this because we can have only 1 DnsDomain with a
    # particular supernet, and FactoryBot always wants to create a new
    # one even if it already exists

    trait :the_10_block do
      before(:create) do |r|
        domain = DnsDomain.find_by(name: '0.0.10.in-addr.arpa') ||
                 (create :dns_domain, :the_10_block)
                 # DnsDomain.create(name:  '0.0.10.in-addr.arpa', type: 'MASTER')

        r.domain_id = domain.id
      end
    end

    trait :the_192_block do
      before(:create) do |r|
        domain = DnsDomain.find_by(name: '0.168.192.in-addr.arpa') ||
                 (create :dns_domain, :the_192_block)

        r.domain_id = domain.id
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
