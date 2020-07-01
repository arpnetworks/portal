# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20200613093259) do

  create_table "accounts", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "login"
    t.string   "password"
    t.string   "first_name"
    t.string   "last_name"
    t.string   "company"
    t.string   "address1"
    t.string   "address2"
    t.string   "city"
    t.string   "state"
    t.string   "zip"
    t.string   "country"
    t.string   "email"
    t.string   "email2",              limit: 256
    t.string   "email_billing",       limit: 256
    t.boolean  "active",                          default: true,  null: false
    t.datetime "visited_at"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "vlan_shutdown",                   default: false, null: false
    t.datetime "vlan_shutdown_at"
    t.boolean  "beta_features",                   default: false, null: false
    t.boolean  "beta_billing_exempt",             default: false, null: false
    t.string   "dk_salt",             limit: 32
  end

  create_table "backup_quotas", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "server"
    t.string   "username",   limit: 64
    t.string   "group",      limit: 64
    t.decimal  "quota",                    precision: 16, default: 1, null: false
    t.string   "home_dir"
    t.string   "chroot_dir"
    t.text     "notes",      limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["server", "username"], name: "index_backup_quotas_on_server_and_username", unique: true, using: :btree
  end

  create_table "bandwidth_quotas", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "commit",                             default: 0,    null: false
    t.string   "commit_unit",          limit: 16,    default: "GB", null: false
    t.float    "commit_overage",       limit: 24,    default: 0.0,  null: false
    t.string   "cacti_username",       limit: 64
    t.string   "cacti_password",       limit: 128
    t.integer  "cacti_local_graph_id"
    t.text     "notes",                limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bgp_sessions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "asn"
    t.string   "peer_host"
    t.string   "peer_ip_address_a"
    t.string   "peer_ip_address_z"
    t.boolean  "multihop",                     default: false, null: false
    t.string   "as_set",            limit: 64
  end

  create_table "bgp_sessions_prefixes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "bgp_session_id",           null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.string   "prefix",                   null: false
    t.integer  "prefixlen",      limit: 2, null: false
    t.integer  "prefixlen_min",  limit: 2
    t.integer  "prefixlen_max",  limit: 2
    t.index ["bgp_session_id"], name: "bgp_session_id", using: :btree
  end

  create_table "charges", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "credit_card_id",                                                          null: false
    t.date     "date"
    t.decimal  "amount",                         precision: 10, scale: 2,                 null: false
    t.text     "gateway_response", limit: 65535
    t.boolean  "success",                                                 default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "refunded_at"
    t.index ["credit_card_id"], name: "credit_card_id", using: :btree
  end

  create_table "credit_cards", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "account_id",                             null: false
    t.string   "month",                    limit: 2
    t.string   "year",                     limit: 4
    t.string   "first_name",               limit: 32
    t.string   "last_name",                limit: 32
    t.string   "display_number",           limit: 32
    t.string   "billing_name"
    t.string   "billing_company"
    t.string   "billing_address_1"
    t.string   "billing_address_2"
    t.string   "billing_city"
    t.string   "billing_state"
    t.string   "billing_postal_code"
    t.string   "billing_country_iso_3166", limit: 2
    t.string   "billing_phone"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "number",                   limit: 65535
    t.datetime "deleted_at"
    t.index ["account_id"], name: "account_id", using: :btree
  end

  create_table "exports", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.datetime "exported_at"
    t.integer  "records"
    t.string   "record_type", limit: 128
  end

  create_table "hosts", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "location_id", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "hostname"
    t.index ["location_id"], name: "location_id", using: :btree
  end

  create_table "invoices", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "account_id",                               null: false
    t.text     "bill_to",    limit: 65535
    t.date     "date"
    t.string   "terms"
    t.text     "message",    limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "paid",                     default: false
    t.boolean  "archived",                 default: false
    t.boolean  "pending",                  default: false
    t.index ["account_id"], name: "account_id", using: :btree
  end

  create_table "invoices_line_items", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "invoice_id",                                                         null: false
    t.date     "date"
    t.string   "code"
    t.text     "description", limit: 65535
    t.decimal  "amount",                    precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["invoice_id"], name: "invoice_id", using: :btree
  end

  create_table "invoices_payments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "invoice_id"
    t.integer  "payment_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["invoice_id"], name: "invoice_id", using: :btree
    t.index ["payment_id"], name: "payment_id", using: :btree
  end

  create_table "ip_blocks", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "ip_block_id"
    t.integer  "location_id"
    t.string   "cidr",        limit: 128
    t.string   "label"
    t.decimal  "network",                   precision: 39,                              unsigned: true
    t.integer  "vlan",        limit: 2,                                                 unsigned: true
    t.integer  "seq",         limit: 2,                                                 unsigned: true
    t.boolean  "routed",                                   default: false, null: false
    t.string   "next_hop",    limit: 128
    t.boolean  "available",                                default: false, null: false
    t.text     "notes",       limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["location_id"], name: "location_id", using: :btree
  end

  create_table "jobs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "account_id",                 null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "jid",          limit: 128,   null: false
    t.integer  "dependent_id"
    t.string   "aasm_state"
    t.string   "code",         limit: 128
    t.string   "description"
    t.text     "args",         limit: 65535
    t.text     "retval",       limit: 65535
    t.text     "reason",       limit: 65535
    t.index ["account_id"], name: "account_id", using: :btree
    t.index ["dependent_id"], name: "dependent_id", using: :btree
    t.index ["jid"], name: "index_jobs_on_jid", unique: true, using: :btree
  end

  create_table "locations", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.string   "code"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "logins", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer  "virtual_machine_id"
    t.string   "username",           limit: 64
    t.string   "password"
    t.string   "iv",                 limit: 64
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["virtual_machine_id"], name: "index_logins_on_virtual_machine_id", using: :btree
  end

  create_table "payments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "account_id",                                                              null: false
    t.text     "reference_number", limit: 65535
    t.date     "date"
    t.text     "description",      limit: 65535
    t.string   "method",           limit: 16
    t.integer  "check_number"
    t.decimal  "amount",                         precision: 10, scale: 2, default: "0.0", null: false
    t.text     "notes",            limit: 65535
    t.text     "raw",              limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["account_id"], name: "account_id", using: :btree
  end

  create_table "pools", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name"
    t.string   "pool_type"
  end

  create_table "resources", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "service_id"
    t.integer "assignable_id"
    t.string  "assignable_type"
    t.index ["service_id", "assignable_id", "assignable_type"], name: "service_id_assignable_id_assignable_type_unique", unique: true, using: :btree
  end

  create_table "sales_receipts", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "account_id",               null: false
    t.text     "sold_to",    limit: 65535
    t.date     "date"
    t.text     "message",    limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["account_id"], name: "account_id", using: :btree
  end

  create_table "sales_receipts_line_items", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "sales_receipt_id",                                                        null: false
    t.string   "code"
    t.text     "description",      limit: 65535
    t.decimal  "amount",                         precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["sales_receipt_id"], name: "sales_receipt_id", using: :btree
  end

  create_table "service_codes", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "name"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "services", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "account_id",                                     null: false
    t.integer  "service_code_id"
    t.string   "title"
    t.text     "description",      limit: 65535
    t.integer  "billing_interval", limit: 2
    t.float    "billing_amount",   limit: 24,    default: 0.0,   null: false
    t.date     "billing_due_on"
    t.date     "date_start"
    t.date     "date_end"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.string   "label"
    t.string   "coupon"
    t.boolean  "pending",                        default: false
    t.index ["account_id"], name: "account_id", using: :btree
    t.index ["service_code_id"], name: "service_code_id", using: :btree
  end

  create_table "ssh_host_keys", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=latin1" do |t|
    t.integer  "virtual_machine_id"
    t.text     "key",                limit: 65535
    t.string   "fingerprint_md5"
    t.string   "fingerprint_sha256"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.index ["virtual_machine_id"], name: "index_ssh_host_keys_on_virtual_machine_id", using: :btree
  end

  create_table "ssh_keys", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "account_id"
    t.string   "name"
    t.text     "key",                limit: 65535
    t.string   "fingerprint_md5"
    t.string   "fingerprint_sha256"
    t.string   "key_type"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "username"
    t.index ["account_id"], name: "index_ssh_keys_on_account_id", using: :btree
  end

  create_table "virtual_machines", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string   "uuid",                limit: 64,    null: false
    t.string   "os",                  limit: 32
    t.integer  "ram"
    t.integer  "storage"
    t.integer  "pool_id"
    t.text     "notes",               limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "console_login",       limit: 64
    t.string   "conserver_password",  limit: 128
    t.string   "host",                limit: 128
    t.integer  "vnc_port"
    t.string   "vnc_password",        limit: 64
    t.string   "label",               limit: 128
    t.string   "os_template",         limit: 128
    t.integer  "websocket_port"
    t.integer  "serial_port"
    t.string   "status",              limit: 64
    t.string   "provisioning_status", limit: 64
    t.index ["pool_id"], name: "pool_id", using: :btree
    t.index ["uuid"], name: "index_virtual_machines_on_uuid", unique: true, using: :btree
  end

  create_table "virtual_machines_interfaces", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "virtual_machine_id"
    t.string   "mac_address"
    t.string   "ip_address"
    t.string   "ip_netmask"
    t.string   "ipv6_address"
    t.string   "ipv6_prefixlen"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "vlans", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer  "vlan",        limit: 2,                 null: false
    t.string   "label"
    t.integer  "location_id"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "shutdown",              default: false, null: false
    t.index ["location_id"], name: "location_id", using: :btree
  end

end
