# encoding: UTF-8
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

ActiveRecord::Schema.define(version: 20200608103428) do

  create_table "accounts", force: :cascade do |t|
    t.string   "login",               limit: 255
    t.string   "password",            limit: 255
    t.string   "first_name",          limit: 255
    t.string   "last_name",           limit: 255
    t.string   "company",             limit: 255
    t.string   "address1",            limit: 255
    t.string   "address2",            limit: 255
    t.string   "city",                limit: 255
    t.string   "state",               limit: 255
    t.string   "zip",                 limit: 255
    t.string   "country",             limit: 255
    t.string   "email",               limit: 255
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
  end

  create_table "backup_quotas", force: :cascade do |t|
    t.string   "server",     limit: 255
    t.string   "username",   limit: 64
    t.string   "group",      limit: 64
    t.decimal  "quota",                    precision: 16, default: 1, null: false
    t.string   "home_dir",   limit: 255
    t.string   "chroot_dir", limit: 255
    t.text     "notes",      limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "backup_quotas", ["server", "username"], name: "index_backup_quotas_on_server_and_username", unique: true, using: :btree

  create_table "bandwidth_quotas", force: :cascade do |t|
    t.integer  "commit",               limit: 4,     default: 0,    null: false
    t.string   "commit_unit",          limit: 16,    default: "GB", null: false
    t.float    "commit_overage",       limit: 24,    default: 0.0,  null: false
    t.string   "cacti_username",       limit: 64
    t.string   "cacti_password",       limit: 128
    t.integer  "cacti_local_graph_id", limit: 4
    t.text     "notes",                limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "bgp_sessions", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.integer  "asn",               limit: 4
    t.string   "peer_host",         limit: 255
    t.string   "peer_ip_address_a", limit: 255
    t.string   "peer_ip_address_z", limit: 255
    t.boolean  "multihop",                      default: false, null: false
    t.string   "as_set",            limit: 64
  end

  create_table "bgp_sessions_prefixes", force: :cascade do |t|
    t.integer  "bgp_session_id", limit: 4,   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.string   "prefix",         limit: 255, null: false
    t.integer  "prefixlen",      limit: 2,   null: false
    t.integer  "prefixlen_min",  limit: 2
    t.integer  "prefixlen_max",  limit: 2
  end

  add_index "bgp_sessions_prefixes", ["bgp_session_id"], name: "bgp_session_id", using: :btree

  create_table "charges", force: :cascade do |t|
    t.integer  "credit_card_id",   limit: 4,                                              null: false
    t.date     "date"
    t.decimal  "amount",                         precision: 10, scale: 2,                 null: false
    t.text     "gateway_response", limit: 65535
    t.boolean  "success",                                                 default: false, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "refunded_at"
  end

  add_index "charges", ["credit_card_id"], name: "credit_card_id", using: :btree

  create_table "credit_cards", force: :cascade do |t|
    t.integer  "account_id",               limit: 4,     null: false
    t.string   "month",                    limit: 2
    t.string   "year",                     limit: 4
    t.string   "first_name",               limit: 32
    t.string   "last_name",                limit: 32
    t.string   "display_number",           limit: 32
    t.string   "billing_name",             limit: 255
    t.string   "billing_company",          limit: 255
    t.string   "billing_address_1",        limit: 255
    t.string   "billing_address_2",        limit: 255
    t.string   "billing_city",             limit: 255
    t.string   "billing_state",            limit: 255
    t.string   "billing_postal_code",      limit: 255
    t.string   "billing_country_iso_3166", limit: 2
    t.string   "billing_phone",            limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.text     "number",                   limit: 65535
    t.datetime "deleted_at"
  end

  add_index "credit_cards", ["account_id"], name: "account_id", using: :btree

  create_table "hosts", force: :cascade do |t|
    t.integer  "location_id", limit: 4,   null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "hostname",    limit: 255
  end

  add_index "hosts", ["location_id"], name: "location_id", using: :btree

  create_table "invoices", force: :cascade do |t|
    t.integer  "account_id", limit: 4,                     null: false
    t.text     "bill_to",    limit: 65535
    t.date     "date"
    t.string   "terms",      limit: 255
    t.text     "message",    limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "paid",                     default: false
    t.boolean  "archived",                 default: false
    t.boolean  "pending",                  default: false
  end

  add_index "invoices", ["account_id"], name: "account_id", using: :btree

  create_table "invoices_line_items", force: :cascade do |t|
    t.integer  "invoice_id",  limit: 4,                                            null: false
    t.date     "date"
    t.string   "code",        limit: 255
    t.text     "description", limit: 65535
    t.decimal  "amount",                    precision: 10, scale: 2, default: 0.0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "invoices_line_items", ["invoice_id"], name: "invoice_id", using: :btree

  create_table "invoices_payments", force: :cascade do |t|
    t.integer  "invoice_id", limit: 4
    t.integer  "payment_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "invoices_payments", ["invoice_id"], name: "invoice_id", using: :btree
  add_index "invoices_payments", ["payment_id"], name: "payment_id", using: :btree

  create_table "ip_blocks", force: :cascade do |t|
    t.integer  "ip_block_id", limit: 4
    t.integer  "location_id", limit: 4
    t.string   "cidr",        limit: 128
    t.string   "label",       limit: 255
    t.decimal  "network",                   precision: 39
    t.integer  "vlan",        limit: 2
    t.integer  "seq",         limit: 2
    t.boolean  "routed",                                   default: false, null: false
    t.string   "next_hop",    limit: 128
    t.boolean  "available",                                default: false, null: false
    t.text     "notes",       limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ip_blocks", ["location_id"], name: "location_id", using: :btree

  create_table "jobs", force: :cascade do |t|
    t.integer  "account_id",   limit: 4,     null: false
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "jid",          limit: 128,   null: false
    t.integer  "dependent_id", limit: 4
    t.string   "aasm_state",   limit: 255
    t.string   "code",         limit: 128
    t.string   "description",  limit: 255
    t.text     "args",         limit: 65535
    t.text     "retval",       limit: 65535
    t.text     "reason",       limit: 65535
  end

  add_index "jobs", ["account_id"], name: "account_id", using: :btree
  add_index "jobs", ["dependent_id"], name: "dependent_id", using: :btree
  add_index "jobs", ["jid"], name: "index_jobs_on_jid", unique: true, using: :btree

  create_table "locations", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.string   "code",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payments", force: :cascade do |t|
    t.integer  "account_id",       limit: 4,                                            null: false
    t.text     "reference_number", limit: 65535
    t.date     "date"
    t.text     "description",      limit: 65535
    t.string   "method",           limit: 16
    t.integer  "check_number",     limit: 4
    t.decimal  "amount",                         precision: 10, scale: 2, default: 0.0, null: false
    t.text     "notes",            limit: 65535
    t.text     "raw",              limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "payments", ["account_id"], name: "account_id", using: :btree

  create_table "pools", force: :cascade do |t|
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "name",       limit: 255
    t.string   "pool_type",  limit: 255
  end

  create_table "resources", force: :cascade do |t|
    t.integer "service_id",      limit: 4
    t.integer "assignable_id",   limit: 4
    t.string  "assignable_type", limit: 255
  end

  add_index "resources", ["service_id", "assignable_id", "assignable_type"], name: "service_id_assignable_id_assignable_type_unique", unique: true, using: :btree

  create_table "sales_receipts", force: :cascade do |t|
    t.integer  "account_id", limit: 4,     null: false
    t.text     "sold_to",    limit: 65535
    t.date     "date"
    t.text     "message",    limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sales_receipts", ["account_id"], name: "account_id", using: :btree

  create_table "sales_receipts_line_items", force: :cascade do |t|
    t.integer  "sales_receipt_id", limit: 4,                                            null: false
    t.string   "code",             limit: 255
    t.text     "description",      limit: 65535
    t.decimal  "amount",                         precision: 10, scale: 2, default: 0.0, null: false
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "sales_receipts_line_items", ["sales_receipt_id"], name: "sales_receipt_id", using: :btree

  create_table "service_codes", force: :cascade do |t|
    t.string   "name",       limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "services", force: :cascade do |t|
    t.integer  "account_id",       limit: 4,                     null: false
    t.integer  "service_code_id",  limit: 4
    t.string   "title",            limit: 255
    t.text     "description",      limit: 65535
    t.integer  "billing_interval", limit: 2
    t.float    "billing_amount",   limit: 24,    default: 0.0,   null: false
    t.date     "billing_due_on"
    t.date     "date_start"
    t.date     "date_end"
    t.datetime "created_at"
    t.datetime "updated_at"
    t.datetime "deleted_at"
    t.string   "label",            limit: 255
    t.string   "coupon",           limit: 255
    t.boolean  "pending",                        default: false
  end

  add_index "services", ["account_id"], name: "account_id", using: :btree
  add_index "services", ["service_code_id"], name: "service_code_id", using: :btree

  create_table "ssh_host_keys", force: :cascade do |t|
    t.integer  "virtual_machine_id", limit: 4
    t.text     "key",                limit: 65535
    t.string   "fingerprint_md5",    limit: 255
    t.string   "fingerprint_sha256", limit: 255
    t.string   "key_type",           limit: 64
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "ssh_host_keys", ["virtual_machine_id"], name: "index_ssh_host_keys_on_virtual_machine_id", using: :btree

  create_table "ssh_keys", force: :cascade do |t|
    t.integer  "account_id",         limit: 4
    t.string   "name",               limit: 255
    t.text     "key",                limit: 65535
    t.string   "fingerprint_md5",    limit: 255
    t.string   "fingerprint_sha256", limit: 255
    t.string   "key_type",           limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "username",           limit: 255
  end

  add_index "ssh_keys", ["account_id"], name: "index_ssh_keys_on_account_id", using: :btree

  create_table "virtual_machines", force: :cascade do |t|
    t.string   "uuid",                limit: 64,    null: false
    t.string   "os",                  limit: 32
    t.integer  "ram",                 limit: 4
    t.integer  "storage",             limit: 4
    t.integer  "pool_id",             limit: 4
    t.text     "notes",               limit: 65535
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "console_login",       limit: 64
    t.string   "conserver_password",  limit: 128
    t.string   "host",                limit: 128
    t.integer  "vnc_port",            limit: 4
    t.string   "vnc_password",        limit: 64
    t.string   "label",               limit: 128
    t.string   "os_template",         limit: 128
    t.integer  "websocket_port",      limit: 4
    t.integer  "serial_port",         limit: 4
    t.string   "status",              limit: 64
    t.string   "provisioning_status", limit: 64
  end

  add_index "virtual_machines", ["pool_id"], name: "pool_id", using: :btree
  add_index "virtual_machines", ["uuid"], name: "index_virtual_machines_on_uuid", unique: true, using: :btree

  create_table "virtual_machines_interfaces", force: :cascade do |t|
    t.integer  "virtual_machine_id", limit: 4
    t.string   "mac_address",        limit: 255
    t.string   "ip_address",         limit: 255
    t.string   "ip_netmask",         limit: 255
    t.string   "ipv6_address",       limit: 255
    t.string   "ipv6_prefixlen",     limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "vlans", force: :cascade do |t|
    t.integer  "vlan",        limit: 2,                   null: false
    t.string   "label",       limit: 255
    t.integer  "location_id", limit: 4
    t.datetime "created_at"
    t.datetime "updated_at"
    t.boolean  "shutdown",                default: false, null: false
  end

  add_index "vlans", ["location_id"], name: "location_id", using: :btree

  add_foreign_key "bgp_sessions_prefixes", "bgp_sessions", name: "bgp_sessions_prefixes_ibfk_1"
  add_foreign_key "charges", "credit_cards", name: "charges_ibfk_1"
  add_foreign_key "credit_cards", "accounts", name: "credit_cards_ibfk_1"
  add_foreign_key "hosts", "locations", name: "hosts_ibfk_1"
  add_foreign_key "invoices", "accounts", name: "invoices_ibfk_1"
  add_foreign_key "invoices_line_items", "invoices", name: "invoices_line_items_ibfk_1"
  add_foreign_key "invoices_payments", "invoices", name: "invoices_payments_ibfk_1"
  add_foreign_key "invoices_payments", "payments", name: "invoices_payments_ibfk_2"
  add_foreign_key "ip_blocks", "locations", name: "ip_blocks_ibfk_1"
  add_foreign_key "jobs", "accounts", name: "jobs_ibfk_1"
  add_foreign_key "jobs", "jobs", column: "dependent_id", name: "jobs_ibfk_2"
  add_foreign_key "payments", "accounts", name: "payments_ibfk_1"
  add_foreign_key "sales_receipts", "accounts", name: "sales_receipts_ibfk_1"
  add_foreign_key "sales_receipts_line_items", "sales_receipts", name: "sales_receipts_line_items_ibfk_1"
  add_foreign_key "services", "accounts", name: "services_ibfk_1"
  add_foreign_key "services", "service_codes", name: "services_ibfk_2"
  add_foreign_key "virtual_machines", "pools", name: "virtual_machines_ibfk_1"
  add_foreign_key "vlans", "locations", name: "vlans_ibfk_1"
end
