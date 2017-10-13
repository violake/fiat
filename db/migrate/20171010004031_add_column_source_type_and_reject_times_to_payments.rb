class AddColumnSourceTypeAndRejectTimesToPayments < ActiveRecord::Migration[5.1]
  def change
    add_column :payments, :source_type, :string
    add_column :payments, :reject_times, :integer, :default => 0
  end
end
