# only for development test
namespace :test_data do
  
  desc 'Raises exception if used in production'
  task skip_prod: [:environment] do
    raise 'You cannot run this in production' if Rails.env.production?
  end

  desc "generate fiat_reconciliation Accounts, Deposits and Withdraws"
  task destory_fiat_data: [:skip_prod] do
    TransferIn.where('updated_at > ?', Time.now - 1.hours).delete_all
    TransferOut.where('updated_at > ?', Time.now - 1.hours).delete_all
    Deposit.where('updated_at > ?', Time.now - 1.hours).delete_all
    Withdraw.where('updated_at > ?', Time.now - 1.hours).delete_all
  end

end