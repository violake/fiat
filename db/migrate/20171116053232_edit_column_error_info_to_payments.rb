class EditColumnErrorInfoToPayments < ActiveRecord::Migration[5.1]
  def change
    change_column :payments, :error_info, :text
  end
end
