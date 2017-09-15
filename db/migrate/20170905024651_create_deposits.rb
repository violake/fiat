class CreateDeposits < ActiveRecord::Migration[5.1]
  def change
    create_table :deposits do |t|
      t.integer :account_id
      t.integer :member_id
      t.string :currency
      t.decimal :lodged_amount, precision: 32, scale: 16
      t.decimal :amount, precision: 32, scale: 16
      t.decimal :fee, precision: 32, scale: 16
      t.string :fund_uid
      t.text :fund_extra
      t.string :txid
      t.integer :state
      t.string :aasm_state
      t.datetime :created_at
      t.datetime :updated_at
      t.datetime :done_at
      t.string :confirmations
      t.string :type
      t.integer :payment_transaction_id
      t.integer :txout

      t.timestamps
    end
  end
end
