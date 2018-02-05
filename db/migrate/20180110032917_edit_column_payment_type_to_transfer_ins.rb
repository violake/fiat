class EditColumnPaymentTypeToTransferIns < ActiveRecord::Migration[5.1]
  def change
    rename_column :transfer_ins, :payment_type, :transfer_type
  end
end
