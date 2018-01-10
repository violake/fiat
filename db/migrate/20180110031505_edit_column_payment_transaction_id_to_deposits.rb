class EditColumnPaymentTransactionIdToDeposits < ActiveRecord::Migration[5.1]
  def change
    rename_column :deposits, :payment_transaction_id, :transfer_in_id
  end
end
