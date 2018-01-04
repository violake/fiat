class CreateTransfers < ActiveRecord::Migration[5.1]
  def change
    create_table :transfers do |t|
      t.string :source_id, limit: 255
      t.string :source_name, limit: 255
      t.string :source_code, limit: 255
      t.string :country, limit:100
      t.string :transaction_type, limit: 50
      t.decimal :amount, precision: 32, scale: 16
      t.string :currency, limit: 50
      t.string :withdraw_ids, limit: 100
      t.string :customer_code, limit: 100
      t.string :result, limit: 30
      t.string :status, limit: 30
      t.datetime :matched_at
      t.string :txid, limit: 255
      t.text :description
      t.text :error_info, limit: 255
      t.integer :send_times, :default => 0
      t.string :source_type, limit: 50
      t.integer :reject_times, :default => 0

      t.timestamps
    end
  end
end
