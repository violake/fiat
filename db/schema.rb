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

ActiveRecord::Schema.define(version: 20180115053017) do

  create_table "deposits", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "account_id"
    t.integer "member_id"
    t.string "currency"
    t.decimal "lodged_amount", precision: 32, scale: 16
    t.decimal "amount", precision: 32, scale: 16
    t.decimal "fee", precision: 32, scale: 16
    t.string "fund_uid"
    t.text "fund_extra"
    t.string "txid"
    t.integer "state"
    t.string "aasm_state"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "done_at"
    t.string "confirmations"
    t.string "type"
    t.integer "transfer_in_id"
    t.integer "txout"
  end

  create_table "transfer_ins", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "source_id"
    t.string "source_name"
    t.string "source_code"
    t.string "country", limit: 100
    t.string "transfer_type", limit: 50
    t.decimal "amount", precision: 32, scale: 16
    t.string "currency", limit: 50
    t.integer "deposit_id"
    t.string "customer_code"
    t.boolean "available"
    t.datetime "available_date"
    t.string "result", limit: 30
    t.string "status", limit: 30
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "matched_at"
    t.string "txid"
    t.text "description"
    t.text "sender_info"
    t.text "error_info"
    t.integer "send_times", default: 0
    t.string "source_type"
    t.integer "reject_times", default: 0
  end

  create_table "transfer_outs", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "source_id"
    t.string "source_name"
    t.string "source_code"
    t.string "country", limit: 100
    t.string "transfer_type", limit: 50
    t.decimal "amount", precision: 32, scale: 16
    t.string "currency", limit: 50
    t.string "withdraw_ids", limit: 100
    t.string "customer_code", limit: 100
    t.string "result", limit: 30
    t.string "status", limit: 30
    t.datetime "matched_at"
    t.string "txid"
    t.text "description"
    t.text "error_info", limit: 255
    t.integer "send_times", default: 0
    t.string "source_type", limit: 50
    t.integer "reject_times", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "lodged_amount", precision: 32, scale: 16
    t.string "email", limit: 100
    t.decimal "fee", precision: 32, scale: 16
  end

  create_table "versions", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8mb4" do |t|
    t.string "item_type", limit: 191, null: false
    t.integer "item_id", null: false
    t.string "event", null: false
    t.string "whodunnit"
    t.text "object", limit: 4294967295
    t.datetime "created_at"
    t.index ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id"
  end

  create_table "withdraws", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.integer "transfer_out_id"
    t.string "sn"
    t.integer "account_id"
    t.integer "member_id"
    t.integer "currency"
    t.decimal "amount", precision: 32, scale: 16
    t.decimal "fee", precision: 32, scale: 16
    t.string "fund_uid"
    t.text "fund_extra"
    t.datetime "done_at"
    t.string "txid"
    t.string "aasm_state"
    t.decimal "sum", precision: 32, scale: 16, default: "0.0", null: false
    t.string "type"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

end
