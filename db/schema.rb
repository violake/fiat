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

ActiveRecord::Schema.define(version: 20170905025754) do

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
    t.integer "payment_transaction_id"
    t.integer "txout"
  end

  create_table "payments", force: :cascade, options: "ENGINE=InnoDB DEFAULT CHARSET=utf8" do |t|
    t.string "source_id"
    t.string "source_name"
    t.string "source_code"
    t.string "country", limit: 100
    t.string "payment_type", limit: 50
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
    t.string "error_info"
  end

end
