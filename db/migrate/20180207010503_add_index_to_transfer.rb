class AddIndexToTransfer < ActiveRecord::Migration[5.1]
  def change
    add_index :transfer_ins, :created_at
    add_index :transfer_ins, :updated_at
    add_index :transfer_outs, :created_at
    add_index :transfer_outs, :updated_at
  end
end
