class ChangeTablenameTransferInsToPayments < ActiveRecord::Migration[5.1]
  def change
    rename_table :payments, :transfer_ins
  end
end
