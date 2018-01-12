class AddColumnLodgedAmountAndEmailToTranferOut < ActiveRecord::Migration[5.1]
  def change
    add_column :transfer_outs, :lodged_amount, :decimal, precision: 32, scale: 16
    add_column :transfer_outs, :email, :string, limit:100
  end
end
