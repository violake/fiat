class AddColumnFeeToTransferOuts < ActiveRecord::Migration[5.1]
  def change
    add_column :transfer_outs, :fee, :decimal, precision: 32, scale: 16
  end
end
