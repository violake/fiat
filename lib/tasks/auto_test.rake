# only for development test
namespace :test_data do
  FIAT_TRANSFER_IN_DESCRIPTION = ['Direct Credit Go MEACHAM 6cnokw', 'Direct Credit Go MEACHAM 2c1c0a',
                                  'Direct Credit Go MEACHAM 2cnokc', 'Direct Credit Go MEACHAM 2afjj3',
                                  'DEPOSIT MR ANDREW JAMES  5cNoK5', 'DEPOSIT LEE RICHARD ANTH  432jklfs  6cnokw']
  FIAT_TRANSFER_OUT_DESCRIPTION = ['WITHDRAWAL ONLINE 1562538 PYMT ZILOLAKHON 12001', 'WITHDRAWAL ONLINE 1543542 PYMT SEUNG WON 12002,12003',
                                   'WITHDRAWAL ONLINE 1543543 PYMT SEUNG WON 12004, 12006', 'WITHDRAWAL ONLINE 1543544 PYMT SEUNG WON 12005,12000',
                                   'WITHDRAWAL ONLINE 1543545 PYMT SEUNG WON 11999', 'WITHDRAWAL MOBILE 1363663 PYMT AHL NAB Peak International',
                                   'WITHDRAWAL ONLINE PYMT GHH HOLDIN 50653 PI']

  
  desc 'Raises exception if used in production'
  task skip_prod: [:environment] do
    raise 'You cannot run this in production' if Rails.env.production?
  end

  desc "generate fiat_reconciliation Accounts, Deposits and Withdraws"
  task destroy_fiat_data: [:skip_prod] do
    FIAT_TRANSFER_IN_DESCRIPTION.each do |description|
      transfer = TransferIn.where("description = ?", description).first
      Deposit.where('id = ?', transfer.deposit_id).each {|d| d.destroy} if transfer.try(:deposit_id)
      transfer.destroy if transfer
    end
    FIAT_TRANSFER_OUT_DESCRIPTION.each do |description|
      transfer = TransferOut.where("description = ?", description).first
      transfer.withdraws.each {|w| w.destroy} if transfer.try(:withdraw_ids)
      transfer.destroy if transfer
    end
  end

  desc "check fiat auto test result"
  task check_result: [:skip_prod] do
    puts "[RESULT] Passed all the tests!" if check_transfer_in && check_transfer_out
  end

  private

  def check_transfer_in
    check_transfer_in_success_case(FIAT_TRANSFER_IN_DESCRIPTION[0], 11001, 125, 123, 1)                                           &&
    check_transfer_error_case('TransferIn', FIAT_TRANSFER_IN_DESCRIPTION[1], 'error', "customer code not found: '2c1c0a'", 2)     &&
    check_transfer_error_case('TransferIn', FIAT_TRANSFER_IN_DESCRIPTION[2], 'error','no deposit waiting to be accepted', 3)      &&
    check_transfer_error_case('TransferIn', FIAT_TRANSFER_IN_DESCRIPTION[3], 'error','missing customer deposit code', 4)          &&
    check_transfer_in_success_case(FIAT_TRANSFER_IN_DESCRIPTION[4], 11004, 1265, 1235, 5)                                         &&
    check_transfer_error_case('TransferIn', FIAT_TRANSFER_IN_DESCRIPTION[5], 'error',"transfer source doesn't match", 6)   
  rescue Exception => e
    puts "[ERROR] in check transfer-in: #{e.message}" 
    puts "[RESULT] TEST failed"
  end

  def check_transfer_out
    check_transfer_out_success_case(FIAT_TRANSFER_OUT_DESCRIPTION[0], 
                                    '6cnokw', 'roger@test.com', 659.34, 666, 6.66, 1)                     &&
    check_transfer_out_success_case(FIAT_TRANSFER_OUT_DESCRIPTION[1], 
                                    '6cnokw', 'roger@test.com', 1318.68, 1332, 13.32, 2)                  &&
    check_transfer_error_case('TransferOut', FIAT_TRANSFER_OUT_DESCRIPTION[2], 
                                'unreconciled', "Missing withdraw: '[12006]'", 3)                         &&
    check_transfer_error_case('TransferOut', FIAT_TRANSFER_OUT_DESCRIPTION[3], 
                                'error', "withdraw ids not match: '12005,12000' but found '12005'", 4)    &&
    check_transfer_error_case('TransferOut', FIAT_TRANSFER_OUT_DESCRIPTION[4], 
                                'error', "withdraw ids not match: '11999' but found ''", 5)               &&
    check_transfer_error_case('TransferOut', FIAT_TRANSFER_OUT_DESCRIPTION[5], 
                                'error', "missing withdraw id", 6)                                        &&
    check_transfer_error_case('TransferOut', FIAT_TRANSFER_OUT_DESCRIPTION[6], 
                                'error', "missing withdraw id", 7)
  rescue Exception => e
    puts "[ERROR] in check transfer-out: #{e.message}" 
    puts "[RESULT] TEST failed" 
  end

  def check_transfer_in_success_case(description, deposit_id, amount, lodged_amount, case_id)
    transfer = TransferIn.find_by(description: description)
    deposit = Deposit.find(deposit_id)
    return true if transfer.result == 'reconciled'              &&
                   transfer.deposit_id == deposit_id            &&
                   deposit.amount.to_f == amount                &&
                   deposit.lodged_amount.to_f == lodged_amount  &&
                   deposit.aasm_state == 'accepted'
    puts "[RESULT] Failed in transfer-in check case #{case_id}"
    false
  rescue ActiveRecord::RecordNotFound => e
    puts "[ERROR] Can not find record. failed in transfer-in check case #{case_id}"
  end

  def check_transfer_error_case(transfer_class, description, result, error_info, case_id)
    transfer = transfer_class.constantize.find_by(description: description)
    return true if transfer.result == result &&
                   transfer.error_info.include?(error_info)
    puts "[RESULT] Failed in transfer-in check case #{case_id}"
    false
  end

  def check_transfer_out_success_case(description, customer_code, email, amount, lodged_amount, fee, case_id)
    transfer = TransferOut.find_by(description: description)
    return true if transfer.result == 'reconciled'              &&
                   transfer.customer_code  == customer_code     &&
                   transfer.email == email                      &&
                   transfer.amount.to_f == amount               &&
                   transfer.lodged_amount.to_f == lodged_amount &&
                   transfer.fee.to_f ==  fee                    &&
                   check_transfer_out_withdraw(transfer)
    puts "[RESULT] Failed in transfer-out check case #{case_id}"
    false
  rescue ActiveRecord::RecordNotFound => e
    puts "[ERROR] Can not find record. failed in transfer-out check case #{case_id}"
  end

  def check_transfer_out_withdraw(transfer)
    withdraws = transfer.withdraws
    withdraws.each do |withdraw|
      return false if !transfer.withdraw_ids.split(",").include?(withdraw.id.to_s)
      return false if withdraw.txid != transfer.txid
    end
    return true
  end

end