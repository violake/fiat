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
        puts "withdraw amount: #{withdraws[0].amount.to_f}"
        puts "withdraw fee: #{withdraws[0].fee.to_f}"
        puts "withdraw sum: #{withdraws[0].sum.to_f}"
        expect(transfer_out.send("can_reconcile?")).to eq(true)
        transfer_out.withdraw_reconcile(withdraw_remote, withdraws[0], response)
        puts "to: #{TransferOut.first.lodged_amount.to_f}"

        expect(response[:success]).to eq(true)
        expect(TransferOut.first.fee).to eq(withdraws[0].fee)
        expect(TransferOut.first.lodged_amount).to eq(withdraws[0].sum)
        expect(TransferOut.first.result).to eq(:reconciled)
        expect(TransferOut.first.result).to eq(:reconciled)

        #puts "after : #{TransferOut.first.inspect}"
        
      end

      it "error when amount incorrect" do
        transfer_out.txid = 10001
        transfer_out.withdraw_ids = withdraws[0].id
        transfer_out.save
        withdraw_remote = { txid: 10001, email: "abc@123.com", customer_code: '123fds4'}
        response = {}

        #puts "initial : #{TransferOut.first.inspect}"

        #puts "to.withdraws : #{transfer_out.withdraws.inspect}"
        expect(transfer_out.withdraws.size).to eq(1)
        expect(transfer_out.result).to eq(:unreconciled)
        expect(transfer_out.withdraw_ids.split(",").size).to eq(1)
        expect(transfer_out.send("can_reconcile?")).to eq(true)
        transfer_out.withdraw_reconcile(withdraw_remote, withdraws[0], response)

        expect(response[:success]).to eq(true)
        expect(TransferOut.first.result).to eq(:error)
        expect(TransferOut.first.error_info).to match(/Amount not even/)

        #puts "after : #{TransferOut.first.inspect}"
        
      end

    end

  end

end