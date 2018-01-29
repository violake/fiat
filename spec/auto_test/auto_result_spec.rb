require 'rails_helper_for_auto'

RSpec.describe 'Auto Test'  do

  describe 'Transfer-in result' do

    context 'Beyond statement result' do

      it 'should reconciled' do
        transfer = TransferIn.find_by(description: 'Direct Credit Go MEACHAM 6cnokw')
        expect(transfer.result).to eq('reconciled')
        expect(transfer.deposit_id).to eq(11001)
        deposit = Deposit.find(11001)
        expect(deposit.amount.to_f).to eq(125)
        expect(deposit.lodged_amount.to_f).to eq(123)
        expect(deposit.aasm_state).to eq('accepted')
      end

      it 'should return error when legal customer code but found no user' do
        transfer = TransferIn.find_by(description: 'Direct Credit Go MEACHAM 2c1c0a')
        expect(transfer.result).to eq('error')
        expect(transfer.error_info).to eq("customer code not found: '2c1c0a'")
      end
      
      it 'should return error when correct customer code but no deposit submitting' do
        transfer = TransferIn.find_by(description: 'Direct Credit Go MEACHAM 2cnokc')
        expect(transfer.result).to eq('error')
        expect(transfer.error_info).to eq('no deposit waiting to be accepted')
      end

      it 'should return error when illegal customer code' do
        transfer = TransferIn.find_by(description: 'Direct Credit Go MEACHAM 2afjj3')
        expect(transfer.result).to eq('error')
        expect(transfer.error_info).to eq('missing customer deposit code')
      end

    end
    
    context 'Westpac statement result' do

      it 'should reconciled' do
        transfer = TransferIn.find_by(description: 'DEPOSIT MR ANDREW JAMES  5cNoK5')
        expect(transfer.result).to eq('reconciled')
        expect(transfer.deposit_id).to eq(11004)
        deposit = Deposit.find(11004)
        expect(deposit.amount.to_f).to eq(1265)
        expect(deposit.lodged_amount.to_f).to eq(1235)
        expect(deposit.aasm_state).to eq('accepted')
      end

      it 'should return error when bank account not match' do
        transfer = TransferIn.find_by(description: 'DEPOSIT LEE RICHARD ANTH  432jklfs  6cnokw')
        expect(transfer.result).to eq('error')
        expect(transfer.error_info).to match(/transfer source doesn't match/)
      end
      
    end

  end

  describe 'Transfer-out result' do

    context 'Westpac statement result' do

      it 'should reconciled when transfer-out : withdrawal = 1:1 ' do
        transfer = TransferOut.find_by(description: 'WITHDRAWAL ONLINE 1562538 PYMT ZILOLAKHON 12001')
        expect(transfer.result).to eq('reconciled')
        expect(transfer.customer_code).to eq('6cnokw')
        expect(transfer.email).to eq('roger@test.com')
        expect(transfer.amount.to_f).to eq(659.34)
        expect(transfer.lodged_amount.to_f).to eq(666)
        expect(transfer.fee.to_f).to eq(6.66)
        withdraw = Withdraw.find(12001)
        expect(withdraw.txid).to eq("1562538")
      end

      it 'should reconciled when transfer-out : withdrawal = 1:2 ' do
        transfer = TransferOut.find_by(description: 'WITHDRAWAL ONLINE 1543542 PYMT SEUNG WON 12002,12003')
        expect(transfer.result).to eq('reconciled')
        expect(transfer.customer_code).to eq('6cnokw')
        expect(transfer.email).to eq('roger@test.com')
        expect(transfer.amount.to_f).to eq(1318.68)
        expect(transfer.lodged_amount.to_f).to eq(1332)
        expect(transfer.fee.to_f).to eq(13.32)
        withdraw = Withdraw.find(12002)
        expect(withdraw.txid).to eq("1543542")
        withdraw = Withdraw.find(12003)
        expect(withdraw.txid).to eq("1543542")
      end

      it 'should return error when transfer-out has 2 withdraw ids but got withdrawals of different customer' do
        transfer = TransferOut.find_by(description: 'WITHDRAWAL ONLINE 1543543 PYMT SEUNG WON 12004, 12006')
        expect(transfer.result).to eq('unreconciled')
        expect(transfer.error_info).to eq("Missing withdraw: '[12006]'")
      end

      it 'should return error when transfer-out has 1 correct withdraw id and 1 incorrect' do
        transfer = TransferOut.find_by(description: 'WITHDRAWAL ONLINE 1543544 PYMT SEUNG WON 12005,12000')
        expect(transfer.result).to eq('error')
        expect(transfer.error_info).to eq("withdraw ids not match: '12005,12000' but found '12005'")
      end
      
      it 'should return error when transfer-out only has 1 incorrect withdraw id' do
        transfer = TransferOut.find_by(description: 'WITHDRAWAL ONLINE 1543545 PYMT SEUNG WON 11999')
        expect(transfer.result).to eq('error')
        expect(transfer.error_info).to eq("withdraw ids not match: '11999' but found ''")
      end

      it 'should return error when transfer-out has no withdraw id' do
        transfer = TransferOut.find_by(description: 'WITHDRAWAL MOBILE 1363663 PYMT AHL NAB Peak International')
        expect(transfer.result).to eq('error')
        expect(transfer.error_info).to eq("missing withdraw id")
      end

      it 'should return error when transfer-out has no txid' do
        transfer = TransferOut.find_by(description: 'WITHDRAWAL ONLINE PYMT GHH HOLDIN 50653 PI')
        expect(transfer.result).to eq('error')
        expect(transfer.error_info).to eq("missing withdraw id")
      end

    end

  end

end