class CreatePayments < ActiveRecord::Migration[5.1]
  def change
    create_table :payments, force: :cascade do |t|
      t.string :source_id, limit: 255
      t.string :source_name, limit: 255
      t.string :source_code, limit: 255
      t.string :country, limit:100
      t.string :payment_type, limit: 50
      t.decimal :amount, precision: 32, scale: 16
      t.string :currency, limit: 50
      t.integer :deposit_id
      t.string :customer_code, limit: 255
      t.boolean :available
      t.datetime :available_date
      t.string :result, limit: 30
      t.string :status, limit: 30
      t.datetime :created_at
      t.datetime :updated_at
      t.datetime :matched_at
      t.string :txid, limit: 255
      t.text :description
      t.text :sender_info
      t.string :error_info, limit: 255

      t.timestamps
    end
  end
end
