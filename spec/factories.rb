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
    password { 'password' }
    password_confirmation { 'password' }

    factory :account_admin do
      login { 'admin' }
      password { 'mysecret' }
      password_confirmation { 'mysecret' }
    end

    factory :account_user do
      login { 'user' }
      email
      password { 'mysecret' }
      password_confirmation { 'mysecret' }
    end
  end

  factory :service do
    account
    service_code
    billing_amount { 5.00 }

    trait :deleted do
      deleted_at { '01/01/1970' }
    end
  end

  factory :service_code do
    factory :service_code_for_ip_block do
      name { 'IP_BLOCK' }
    end
  end

  factory :ssh_key do
    account
  end

  factory :ssh_host_key do
    virtual_machine
  end

  factory :resource do
    service
  end

  factory :location do
    name { 'Los Angeles' }

    sequence :code do |n|
      "lax-#{n}"
    end
  end

  factory :ip_block do
    location
    cidr { '10.0.0.0/30' }
    vlan { '100' }
    after(:create) do |ip|
      ip.resource = create(:resource, assignable: ip)
    end

    trait :available do
      available { true }
    end

    factory :ip_block_super do
      cidr { '208.79.88.0/21' }
      vlan { '102' }
    end

    factory :ip_block_smaller do
      cidr { '208.79.88.0/24' }
      vlan { '105' }
    end
  end

  factory :vlan do
    location
    vlan { 100 }
  end

  factory :host do
    location
  end

  factory :virtual_machine do
    sequence :uuid do |_n|
      UUID.generate
    end
    sequence :label do |n|
      "foo#{n}"
    end
    host  { 'kct01.arpnetworks.com' }
    ram   { 1024 }
    storage { 20 }
    after(:create) do |vm|
      vm.resource = create(:resource, assignable: vm)
    end
  end

  factory :bandwidth_quota do
    cacti_username { 'johndoe' }
    cacti_password { 'peeword' }
    cacti_local_graph_id { 1000 }
    after(:create) do |bq|
      bq.resource = create(:resource, assignable: bq)
    end
  end

  factory :dns_domain do
    type { 'MASTER' }

    trait :the_10_block do
      name { '0.0.10.in-addr.arpa' }
    end
    trait :the_192_block do
      name { '0.168.192.in-addr.arpa' }
    end
    trait :the_ipv6_block do
      name { '8.f.2.f.7.0.6.2.ip6.arpa' }
    end
  end

  factory :stripe_event do
    status { 'received' }

    trait :invoice_finalized do
      event_id { 'evt_1K3efs2LsKuf8PTnpoVeaELt' }
      event_type { 'invoice.finalized' }
      body {

"{\n  \"id\": \"evt_1K411U2LsKuf8PTnFWG92LV8\",\n  \"object\": \"event\",\n  \"api_version\": \"2020-08-27\",\n  \"created\": 1638873347,\n  \"data\": {\n    \"object\": {\n      \"id\": \"in_1K411S2LsKuf8PTn6WkcBmOf\",\n      \"object\": \"invoice\",\n      \"account_country\": \"US\",\n      \"account_name\": \"ARP Networks, Inc.\",\n      \"account_tax_ids\": null,\n      \"amount_due\": 2000,\n      \"amount_paid\": 0,\n      \"amount_remaining\": 2000,\n      \"application_fee_amount\": null,\n      \"attempt_count\": 0,\n      \"attempted\": false,\n      \"auto_advance\": false,\n      \"automatic_tax\": {\n        \"enabled\": false,\n        \"status\": null\n      },\n      \"billing_reason\": \"manual\",\n      \"charge\": null,\n      \"collection_method\": \"charge_automatically\",\n      \"created\": 1638873346,\n      \"currency\": \"usd\",\n      \"custom_fields\": null,\n      \"customer\": \"cus_KjTz4LjhOlhqM5\",\n      \"customer_address\": null,\n      \"customer_email\": null,\n      \"customer_name\": null,\n      \"customer_phone\": null,\n      \"customer_shipping\": null,\n      \"customer_tax_exempt\": \"none\",\n      \"customer_tax_ids\": [\n\n      ],\n      \"default_payment_method\": null,\n      \"default_source\": null,\n      \"default_tax_rates\": [\n\n      ],\n      \"description\": \"(created by Stripe CLI)\",\n      \"discount\": null,\n      \"discounts\": [\n\n      ],\n      \"due_date\": null,\n      \"ending_balance\": 0,\n      \"footer\": null,\n      \"hosted_invoice_url\": \"https://invoice.stripe.com/i/acct_103mHD2LsKuf8PTn/test_YWNjdF8xMDNtSEQyTHNLdWY4UFRuLF9LalR6R3g2Z280NWpKMkVIbFNaVjZpNEdhYnFTV1JN0100rdSNdpJA\",\n      \"invoice_pdf\": \"https://pay.stripe.com/invoice/acct_103mHD2LsKuf8PTn/test_YWNjdF8xMDNtSEQyTHNLdWY4UFRuLF9LalR6R3g2Z280NWpKMkVIbFNaVjZpNEdhYnFTV1JN0100rdSNdpJA/pdf\",\n      \"last_finalization_error\": null,\n      \"lines\": {\n        \"object\": \"list\",\n        \"data\": [\n          {\n            \"id\": \"il_1K411R2LsKuf8PTni5jcJzgV\",\n            \"object\": \"line_item\",\n            \"amount\": 2000,\n            \"currency\": \"usd\",\n            \"description\": \"(created by Stripe CLI)\",\n            \"discount_amounts\": [\n\n            ],\n            \"discountable\": true,\n            \"discounts\": [\n\n            ],\n            \"invoice_item\": \"ii_1K411R2LsKuf8PTnwDydd8Dq\",\n            \"livemode\": false,\n            \"metadata\": {\n            },\n            \"period\": {\n              \"end\": 1638873345,\n              \"start\": 1638873345\n            },\n            \"plan\": null,\n            \"price\": {\n              \"id\": \"price_1K411R2LsKuf8PTnCMX9peT7\",\n              \"object\": \"price\",\n              \"active\": false,\n              \"billing_scheme\": \"per_unit\",\n              \"created\": 1638873345,\n              \"currency\": \"usd\",\n              \"livemode\": false,\n              \"lookup_key\": null,\n              \"metadata\": {\n              },\n              \"nickname\": null,\n              \"product\": \"prod_KjTzZyZNJPbROQ\",\n              \"recurring\": null,\n              \"tax_behavior\": \"unspecified\",\n              \"tiers_mode\": null,\n              \"transform_quantity\": null,\n              \"type\": \"one_time\",\n              \"unit_amount\": 2000,\n              \"unit_amount_decimal\": \"2000\"\n            },\n            \"proration\": false,\n            \"quantity\": 1,\n            \"subscription\": null,\n            \"tax_amounts\": [\n\n            ],\n            \"tax_rates\": [\n\n            ],\n            \"type\": \"invoiceitem\"\n          }\n        ],\n        \"has_more\": false,\n        \"total_count\": 1,\n        \"url\": \"/v1/invoices/in_1K411S2LsKuf8PTn6WkcBmOf/lines\"\n      },\n      \"livemode\": false,\n      \"metadata\": {\n      },\n      \"next_payment_attempt\": null,\n      \"number\": \"F6259BD1-0001\",\n      \"on_behalf_of\": null,\n      \"paid\": false,\n      \"payment_intent\": \"pi_3K411T2LsKuf8PTn0pxoncxQ\",\n      \"payment_settings\": {\n        \"payment_method_options\": null,\n        \"payment_method_types\": null\n      },\n      \"period_end\": 1638873346,\n      \"period_start\": 1638873346,\n      \"post_payment_credit_notes_amount\": 0,\n      \"pre_payment_credit_notes_amount\": 0,\n      \"quote\": null,\n      \"receipt_number\": null,\n      \"starting_balance\": 0,\n      \"statement_descriptor\": null,\n      \"status\": \"open\",\n      \"status_transitions\": {\n        \"finalized_at\": 1638873347,\n        \"marked_uncollectible_at\": null,\n        \"paid_at\": null,\n        \"voided_at\": null\n      },\n      \"subscription\": null,\n      \"subtotal\": 2000,\n      \"tax\": null,\n      \"total\": 2000,\n      \"total_discount_amounts\": [\n\n      ],\n      \"total_tax_amounts\": [\n\n      ],\n      \"transfer_data\": null,\n      \"webhooks_delivered_at\": 1638873347\n    }\n  },\n  \"livemode\": false,\n  \"pending_webhooks\": 1,\n  \"request\": {\n    \"id\": \"req_eQAWg3aw5JaoDb\",\n    \"idempotency_key\": \"6eba4ce8-6c20-4757-8020-c3326e51ed34\"\n  },\n  \"type\": \"invoice.finalized\"\n}"

 }

    end

    trait :invoice_paid do
      event_id { 'evt_1K4QFg2LsKuf8PTnOKcRuDpe' }
      event_type { 'invoice.paid' }
      body {
        "{\n  \"id\": \"evt_1K4QFg2LsKuf8PTnOKcRuDpe\",\n  \"object\": \"event\",\n  \"api_version\": \"2020-08-27\",\n  \"created\": 1638970327,\n  \"data\": {\n    \"object\": {\n      \"id\": \"in_1K4Q9t2LsKuf8PTnhAJk35dt\",\n      \"object\": \"invoice\",\n      \"account_country\": \"US\",\n      \"account_name\": \"ARP Networks, Inc.\",\n      \"account_tax_ids\": null,\n      \"amount_due\": 3000,\n      \"amount_paid\": 0,\n      \"amount_remaining\": 3000,\n      \"application_fee_amount\": null,\n      \"attempt_count\": 0,\n      \"attempted\": false,\n      \"auto_advance\": false,\n      \"automatic_tax\": {\n        \"enabled\": false,\n        \"status\": null\n      },\n      \"billing_reason\": \"manual\",\n      \"charge\": null,\n      \"collection_method\": \"send_invoice\",\n      \"created\": 1638969969,\n      \"currency\": \"usd\",\n      \"custom_fields\": null,\n      \"customer\": \"cus_KjTzOhXWMXPisF\",\n      \"customer_address\": null,\n      \"customer_email\": null,\n      \"customer_name\": \"Curtis and Johnny\",\n      \"customer_phone\": null,\n      \"customer_shipping\": null,\n      \"customer_tax_exempt\": \"none\",\n      \"customer_tax_ids\": [\n\n      ],\n      \"default_payment_method\": null,\n      \"default_source\": null,\n      \"default_tax_rates\": [\n\n      ],\n      \"description\": \"Thank you for your business!\",\n      \"discount\": null,\n      \"discounts\": [\n\n      ],\n      \"due_date\": 1641562019,\n      \"ending_balance\": 0,\n      \"footer\": null,\n      \"hosted_invoice_url\": \"https://invoice.stripe.com/i/acct_103mHD2LsKuf8PTn/test_YWNjdF8xMDNtSEQyTHNLdWY4UFRuLF9LanR4VmVVMmttR3lycEE5RWlZMTk4M1hnbWQyNW9u0100TucxWkmh\",\n      \"invoice_pdf\": \"https://pay.stripe.com/invoice/acct_103mHD2LsKuf8PTn/test_YWNjdF8xMDNtSEQyTHNLdWY4UFRuLF9LanR4VmVVMmttR3lycEE5RWlZMTk4M1hnbWQyNW9u0100TucxWkmh/pdf\",\n      \"last_finalization_error\": null,\n      \"lines\": {\n        \"object\": \"list\",\n        \"data\": [\n          {\n            \"id\": \"il_1K4QAd2LsKuf8PTnhUV6K1Yd\",\n            \"object\": \"line_item\",\n            \"amount\": 2000,\n            \"currency\": \"usd\",\n            \"description\": \"All-Purpose VPS\",\n            \"discount_amounts\": [\n\n            ],\n            \"discountable\": true,\n            \"discounts\": [\n\n            ],\n            \"invoice_item\": \"ii_1K4QAd2LsKuf8PTnjBkJdWrf\",\n            \"livemode\": false,\n            \"metadata\": {\n            },\n            \"period\": {\n              \"end\": 1638970015,\n              \"start\": 1638970015\n            },\n            \"plan\": null,\n            \"price\": {\n              \"id\": \"price_1K4NG92LsKuf8PTnmaVWEYlr\",\n              \"object\": \"price\",\n              \"active\": true,\n              \"billing_scheme\": \"per_unit\",\n              \"created\": 1638958825,\n              \"currency\": \"usd\",\n              \"livemode\": false,\n              \"lookup_key\": null,\n              \"metadata\": {\n              },\n              \"nickname\": null,\n              \"product\": \"prod_Kjqyw4m7aCpIY4\",\n              \"recurring\": null,\n              \"tax_behavior\": \"unspecified\",\n              \"tiers_mode\": null,\n              \"transform_quantity\": null,\n              \"type\": \"one_time\",\n              \"unit_amount\": 2000,\n              \"unit_amount_decimal\": \"2000\"\n            },\n            \"proration\": false,\n            \"quantity\": 1,\n            \"subscription\": null,\n            \"tax_amounts\": [\n\n            ],\n            \"tax_rates\": [\n\n            ],\n            \"type\": \"invoiceitem\"\n          },\n          {\n            \"id\": \"il_1K4QAY2LsKuf8PTn82AEVpja\",\n            \"object\": \"line_item\",\n            \"amount\": 1000,\n            \"currency\": \"usd\",\n            \"description\": \"Small VPS\",\n            \"discount_amounts\": [\n\n            ],\n            \"discountable\": true,\n            \"discounts\": [\n\n            ],\n            \"invoice_item\": \"ii_1K4QAY2LsKuf8PTnyMVtwTk1\",\n            \"livemode\": false,\n            \"metadata\": {\n            },\n            \"period\": {\n              \"end\": 1638970010,\n              \"start\": 1638970010\n            },\n            \"plan\": null,\n            \"price\": {\n              \"id\": \"price_1K4NGO2LsKuf8PTnLdaiu1AW\",\n              \"object\": \"price\",\n              \"active\": true,\n              \"billing_scheme\": \"per_unit\",\n              \"created\": 1638958840,\n              \"currency\": \"usd\",\n              \"livemode\": false,\n              \"lookup_key\": null,\n              \"metadata\": {\n              },\n              \"nickname\": null,\n              \"product\": \"prod_KjqyjiovWL6OoV\",\n              \"recurring\": null,\n              \"tax_behavior\": \"unspecified\",\n              \"tiers_mode\": null,\n              \"transform_quantity\": null,\n              \"type\": \"one_time\",\n              \"unit_amount\": 1000,\n              \"unit_amount_decimal\": \"1000\"\n            },\n            \"proration\": false,\n            \"quantity\": 1,\n            \"subscription\": null,\n            \"tax_amounts\": [\n\n            ],\n            \"tax_rates\": [\n\n            ],\n            \"type\": \"invoiceitem\"\n          }\n        ],\n        \"has_more\": false,\n        \"total_count\": 2,\n        \"url\": \"/v1/invoices/in_1K4Q9t2LsKuf8PTnhAJk35dt/lines\"\n      },\n      \"livemode\": false,\n      \"metadata\": {\n      },\n      \"next_payment_attempt\": null,\n      \"number\": \"F681C505-0016\",\n      \"on_behalf_of\": null,\n      \"paid\": true,\n      \"payment_intent\": null,\n      \"payment_settings\": {\n        \"payment_method_options\": null,\n        \"payment_method_types\": null\n      },\n      \"period_end\": 1638969969,\n      \"period_start\": 1638969969,\n      \"post_payment_credit_notes_amount\": 0,\n      \"pre_payment_credit_notes_amount\": 0,\n      \"quote\": null,\n      \"receipt_number\": null,\n      \"starting_balance\": 0,\n      \"statement_descriptor\": null,\n      \"status\": \"paid\",\n      \"status_transitions\": {\n        \"finalized_at\": 1638970019,\n        \"marked_uncollectible_at\": null,\n        \"paid_at\": 1638970327,\n        \"voided_at\": null\n      },\n      \"subscription\": null,\n      \"subtotal\": 3000,\n      \"tax\": null,\n      \"total\": 3000,\n      \"total_discount_amounts\": [\n\n      ],\n      \"total_tax_amounts\": [\n\n      ],\n      \"transfer_data\": null,\n      \"webhooks_delivered_at\": 1638969969\n    }\n  },\n  \"livemode\": false,\n  \"pending_webhooks\": 3,\n  \"request\": {\n    \"id\": \"req_7arApg9X9W83a7\",\n    \"idempotency_key\": \"a075bc5a-e0ea-4647-a9bd-3580a7d6cf94\"\n  },\n  \"type\": \"invoice.paid\"\n}"
      }
    end
  end

  factory :dns_record do
    # association :dns_domain, :the_10_block
    name { '2.0.0.10.in-addr.arpa' }
    content { 'example.com' }

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
    server { 'backup01.cust.arpnetworks.com' }
    username { 'garry' }
    group { 'sftpusers' }
    quota { 20_000_000 }
    home_dir { '/home/sftpusers/home/garry' }
    chroot_dir { '/home/sftpusers/home' }
    notes { '' }
  end

  factory :credit_card do
    association :account
    display_number { '1111' }
    number { 4_111_111_111_111_111 }
    month { '12' }
    year { '2036' }
    first_name { 'John' }
    last_name { 'Doe' }
    billing_country_iso_3166 { 'US' }
  end
end
