class AddColumnSendtimesToPayments < ActiveRecord::Migration[5.1]
  def change
    add_column :payments, :send_times, :integer, :default => 0
  end
end
