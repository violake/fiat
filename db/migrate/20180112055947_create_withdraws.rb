class CreateWithdraws < ActiveRecord::Migration[5.1]
  def change
    create_table :withdraws do |t|
      t.string   :sn
      t.integer  :account_id
      t.integer  :member_id
      t.string   :currency
      t.decimal  :amount,     precision: 32, scale: 16
      t.decimal  :fee,        precision: 32, scale: 16
      t.string   :fund_uid
      t.text     :fund_extra
      t.datetime :done_at
      t.string   :txid
      t.string   :aasm_state
      t.decimal  :sum,        precision: 32, scale: 16, default: 0.0, null: false
      t.string   :class_name

      t.timestamps
    end
  end
end
