require 'rails_helper'

RSpec.describe TransferOut, type: :model do
  let(:transfer_out) { create(:new_transfer_out) }
  let(:withdraws) { create_list(:withdraw, 10) }

  it { should validate_presence_of(:source_id) }
  it { should validate_presence_of(:source_name) }
  it { should validate_presence_of(:source_code) }
  it { should validate_presence_of(:transfer_type) }
  it { should validate_presence_of(:amount) }
  it { should validate_presence_of(:currency) }
  it { should validate_uniqueness_of(:source_id).scoped_to(:source_code)  }
  it { should validate_uniqueness_of(:txid) }


  describe "transfer-out doing withdraw_reconcile" do

    context 'when transfer-out:withdraw = 1:1' do

      it "reconciled when data correct" do
        transfer_out.txid = 10001
        transfer_out.withdraw_ids = withdraws[0].id
        transfer_out.amount = withdraws[0].amount
        transfer_out.save
        withdraw_remote = { txid: 10001, email: "abc@123.com", customer_code: '123fds4'}
        response = {}

        #puts "initial : #{TransferOut.first.inspect}"

        #puts "to.withdraws : #{transfer_out.withdraws.inspect}"
        expect(transfer_out.send("can_reconcile?")).to eq(true)
        transfer_out.my_withdrawal?(withdraw_remote, response)
        transfer_out.withdraw_reconcile
        puts "to: #{TransferOut.first.lodged_amount.to_f}"

        expect(response[:success]).to eq(true)
        expect(TransferOut.first.fee).to eq(withdraws[0].fee)
        expect(TransferOut.first.lodged_amount).to eq(withdraws[0].sum)
        expect(TransferOut.first.result).to eq(:reconciled)

        #puts "after : #{TransferOut.first.inspect}"
        
      end

      it "error when amount incorrect" do
        transfer_out.txid = 10001
        transfer_out.withdraw_ids = withdraws[0].id
        transfer_out.amount = withdraws[0].sum
        transfer_out.save
        withdraw_remote = { txid: 10001, email: "abc@123.com", customer_code: '123fds4'}
        response = {}

        #puts "initial : #{TransferOut.first.inspect}"

        #puts "to.withdraws : #{transfer_out.withdraws.inspect}"
        expect(transfer_out.send("can_reconcile?")).to eq(true)
        transfer_out.my_withdrawal?(withdraw_remote, response)
        transfer_out.withdraw_reconcile

        expect(response[:success]).to eq(true)
        expect(TransferOut.first.result).to eq(:error)
        expect(TransferOut.first.fee).to eq(withdraws[0].fee)
        expect(TransferOut.first.lodged_amount).to eq(withdraws[0].sum)
        expect(TransferOut.first.error_info).to match(/Amount not even/)

        #puts "after : #{TransferOut.first.inspect}"
        
      end

      it "error when params missing" do
        withdraw_remote = { email: "abc@123.com", customer_code: '123fds4'}
        response = {}
        transfer_out.my_withdrawal?(withdraw_remote, response)
        transfer_out.withdraw_reconcile
        expect(response[:success]).to eq(false)
        expect(response[:error]).to match(/missing params: 'txid'/)

        withdraw_remote = { txid: 10001, customer_code: '123fds4'}
        response = {}
        transfer_out.my_withdrawal?(withdraw_remote, response)
        transfer_out.withdraw_reconcile
        expect(response[:success]).to eq(false)
        expect(response[:error]).to match(/missing params: 'email'/)
        
        
        withdraw_remote = { txid: 10001, email: "abc@123.com"}
        response = {}
        transfer_out.my_withdrawal?(withdraw_remote, response)
        transfer_out.withdraw_reconcile
        expect(response[:success]).to eq(false)
        expect(response[:error]).to match(/missing params: 'customer_code'/)
      end

      it "error when params error" do
        transfer_out.txid = 10002
        transfer_out.save
        withdraw_remote = { txid: 10001, email: "abc@123.com", customer_code: '123fds4'}
        response = {}
        transfer_out.my_withdrawal?(withdraw_remote, response)
        transfer_out.withdraw_reconcile
        expect(response[:success]).to eq(false)
        expect(response[:error]).to match(/txid not match: [transfer-out: '10002', withdraw: '10001']/)

      end

    end

    context 'when transfer-out:withdraw = 1:n' do

      it "do not reconcile when not all withdraws are received " do
        transfer_out.txid = 10001
        transfer_out.withdraw_ids = withdraws[0].id.to_s + "," + withdraws[1].id.to_s
        transfer_out.amount = withdraws[0].amount + withdraws[1].amount
        transfer_out.save

        # reconcile withdrawal 1
        withdraw_remote = { txid: 10001, email: "abc@123.com", customer_code: '123fds4'}
        response = {}
        expect(transfer_out.send("can_reconcile?")).to eq(true)
        transfer_out.my_withdrawal?(withdraw_remote, response)
        transfer_out.withdraw_reconcile
        transfer_out = TransferOut.first
        expect(response[:success]).to eq(true)
        expect(transfer_out.lodged_amount).to eq(withdraws[0].amount)
        expect(transfer_out.fee).to eq(withdraws[0].fee)
        expect(transfer_out.result).to eq(:unreconciled)
        expect(transfer_out.error_info).to eq("Missing withdraw: '10002'")

        # reconcile withdrawal 2
        withdraw_remote[:txid] = 10002
        expect(transfer_out.send("can_reconcile?")).to eq(true)
        transfer_out.my_withdrawal?(withdraw_remote, response)
        transfer_out.withdraw_reconcile
        transfer_out = TransferOut.first
        expect(response[:success]).to eq(true)
        expect(transfer_out.lodged_amount).to eq(withdraws[0].amount + withdraw[1].amount)
        expect(transfer_out.fee).to eq(withdraws[0].fee + withdraw[1].fee)
        expect(transfer_out.result).to eq(:reconciled)
        expect(transfer_out.error_info).to eq(nil)


      end

    end

  end

end