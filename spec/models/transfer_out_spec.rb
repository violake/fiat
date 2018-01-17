require 'rails_helper'

RSpec.describe TransferOut, type: :model do
  let(:transfer_outs) { create_list(:new_transfer_out, 10) }
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
        transfer_out = transfer_outs[0]
        withdraw = withdraws[0]
        transfer_out.txid = 10001
        transfer_out.withdraw_ids = withdraw.id
        transfer_out.amount = withdraw.amount
        transfer_out.save
        withdraw_remote = { "txid"=> "10001", "email"=> "abc@123.com", "customer_code"=> '123fds4'}
        response = {}

        #puts "initial : #{TransferOut.first.inspect}"

        #puts "to.withdraws : #{transfer_out.withdraws.inspect}"
        expect(transfer_out.send("can_reconcile?")).to eq(true)
        transfer_out.withdraw_reconcile(response)
        transfer_out = TransferOut.find(transfer_out.id)
	      expect(response[:success]).to eq(true)
        expect(transfer_out.fee).to eq(withdraw.fee)
        expect(transfer_out.lodged_amount).to eq(withdraw.sum)
        expect(transfer_out.result).to eq(:reconciled)

        #puts "after : #{TransferOut.first.inspect}"
        
      end

      it "error when amount incorrect" do
        transfer_out = transfer_outs[1]
        withdraw = withdraws[0]        
        transfer_out.txid = 10001
        transfer_out.withdraw_ids = withdraw.id
        transfer_out.amount = withdraw.sum
        transfer_out.save
        withdraw_remote = { "txid"=> "10001", "email"=> "abc@123.com", "customer_code"=> '123fds4'}
        response = {}

        #puts "initial : #{TransferOut.first.inspect}"

        #puts "to.withdraws : #{transfer_out.withdraws.inspect}"
        expect(transfer_out.send("can_reconcile?")).to eq(true)
        transfer_out.withdraw_reconcile(response)
	      transfer_out = TransferOut.find(transfer_out.id)
        expect(response[:success]).to eq(true)
        expect(transfer_out.result).to eq(:error)
        expect(transfer_out.fee).to eq(withdraw.fee)
        expect(transfer_out.lodged_amount).to eq(withdraw.sum)
        expect(transfer_out.error_info).to match(/Amount not even/)

        #puts "after : #{TransferOut.first.inspect}"
        
      end

      it "error when params missing" do
        transfer_out = transfer_outs[2]
        transfer_out.withdraw_ids = "321"
        transfer_out.save
        withdraw_remote = { "email"=> "abc@123.com", "customer_code"=> '123fds4', "withdraw_id"=> 321}
        response = {}
        expect(transfer_out.withdraws.size).to eq(0)
        expect(transfer_out.withdraw_ids.split(",").size).to eq(1)
        expect(transfer_out.send("match_all_withdraws?")).to eq(false)
        expect(transfer_out.my_withdrawal?(withdraw_remote, response)).to eq(false)
        expect(transfer_out.send("can_reconcile?")).to eq(true)
        expect(response[:success]).to eq(false)
        expect(response[:error]).to match(/missing params: 'txid'/)

        withdraw_remote = { "txid"=> "10001", "customer_code"=> '123fds4', "withdraw_id"=> 321}
        response = {}
        expect(transfer_out.my_withdrawal?(withdraw_remote, response)).to eq(false)
        expect(response[:success]).to eq(false)
        expect(response[:error]).to match(/missing params: 'email'/)
        
        withdraw_remote = { "txid"=> "10001", "email"=> "abc@123.com", "withdraw_id"=> "321"}
        response = {}
        expect(transfer_out.my_withdrawal?(withdraw_remote, response)).to eq(false)
        expect(response[:success]).to eq(false)
        expect(response[:error]).to match(/missing params: 'customer_code'/)
      end

      it "error when params error" do
        transfer_out = transfer_outs[3]
        transfer_out.withdraw_ids = "321"
        transfer_out.txid = 10002
        transfer_out.save
        withdraw_remote = { "txid"=> "10001", "email"=> "abc@123.com", "customer_code"=> '123fds4', "withdraw_id"=> 321}
        response = {}
        expect(transfer_out.my_withdrawal?(withdraw_remote, response)).to eq(false)
        expect(response[:success]).to eq(false)
        expect(response[:error]).to eq("txid not match: [transfer-out: '10002', withdraw: '10001']")
      end

    end

    context 'when transfer-out:withdraw = 1:n' do

      it "do not reconcile when not all withdraws are received " do
        transfer_out = transfer_outs[5]
        withdraw_a = withdraws[1]
        withdraw_b = withdraws[2]
        transfer_out.txid = 10003
        transfer_out.withdraw_ids = withdraw_a.id.to_s + ",321"
        transfer_out.amount = withdraw_a.amount + withdraw_b.amount
        transfer_out.save

        # reconcile withdrawal 1 not reconciled
        withdraw_remote = { "txid"=> "10003", "email"=> "abc@123.com", "customer_code"=> '123fds4', "withdraw_id"=> withdraw_a.id}
        response = {}
        expect(transfer_out.send("can_reconcile?")).to eq(true)
        expect(transfer_out.send("match_all_withdraws?")).to eq(false)
        expect(transfer_out.my_withdrawal?(withdraw_remote, response)).to eq(true)
        transfer_out.withdraw_reconcile(response)
        transfer_out = TransferOut.find(transfer_out.id)
        expect(response[:success]).to eq(true)
        expect(transfer_out.lodged_amount).to eq(withdraw_a.sum)
        expect(transfer_out.fee).to eq(withdraw_a.fee)
        expect(transfer_out.result).to eq(:unreconciled)
        expect(transfer_out.error_info).to eq("Missing withdraw: '[321]'")

        # reconcile withdrawal 2 reconciled
        transfer_out.withdraw_ids = withdraw_a.id.to_s + "," + withdraw_b.id.to_s
        transfer_out.save
        expect(transfer_out.send("can_reconcile?")).to eq(true)
        expect(transfer_out.my_withdrawal?(withdraw_remote, response)).to eq(false)
        transfer_out.withdraw_reconcile(response)
        transfer_out = TransferOut.find(transfer_out.id)
        expect(response[:success]).to eq(true)
        expect(transfer_out.amount).to eq(withdraw_a.amount + withdraw_b.amount)
        expect(transfer_out.lodged_amount).to eq(withdraw_a.sum + withdraw_b.sum)
        expect(transfer_out.fee).to eq(withdraw_a.fee + withdraw_b.fee)
        expect(transfer_out.result).to eq(:reconciled)
        expect(transfer_out.error_info).to eq(nil)
      end

      it "reconciling error when received all withdrawals and amount not even " do
        transfer_out = transfer_outs[6]
        withdraw_a = withdraws[3]
        withdraw_b = withdraws[4]
        transfer_out.txid = 10004
        transfer_out.withdraw_ids = withdraw_a.id.to_s + ",321"
        transfer_out.amount = withdraw_a.amount + 666
        transfer_out.save

        # reconcile withdrawal 1 not reconciled
        withdraw_remote = { "txid"=> "10004", "email"=> "abc@321.com", "customer_code"=> '5asdfds4', "withdraw_id"=> withdraw_a.id}
        response = {}
        expect(transfer_out.send("can_reconcile?")).to eq(true)
        expect(transfer_out.my_withdrawal?(withdraw_remote, response)).to eq(true)
        transfer_out.withdraw_reconcile(response)
        transfer_out = TransferOut.find(transfer_out.id)
        expect(response[:success]).to eq(true)
        expect(transfer_out.lodged_amount).to eq(withdraw_a.sum)
        expect(transfer_out.fee).to eq(withdraw_a.fee)
        expect(transfer_out.result).to eq(:unreconciled)
        expect(transfer_out.error_info).to eq("Missing withdraw: '[321]'")

        # reconcile withdrawal 2 reconciled
        transfer_out.withdraw_ids = withdraw_a.id.to_s + "," + withdraw_b.id.to_s
        transfer_out.save
        withdraw_remote["withdraw_id"] = withdraw_b.id.to_s
        expect(transfer_out.send("can_reconcile?")).to eq(true)
        expect(transfer_out.my_withdrawal?(withdraw_remote, response)).to eq(false)
        transfer_out.withdraw_reconcile(response)
        transfer_out = TransferOut.find(transfer_out.id)
        expect(response[:success]).to eq(true)
        expect(transfer_out.lodged_amount).to eq(withdraw_a.sum + withdraw_b.sum)
        expect(transfer_out.fee).to eq(withdraw_a.fee + withdraw_b.fee)
        expect(transfer_out.result).to eq(:error)
        expect(transfer_out.error_info).to match(/Amount not even/)

      end

      it "return error when received all wrong withdrawal" do
        transfer_out = transfer_outs[7]
        withdraw_a = withdraws[5]
        withdraw_b = withdraws[6]
        transfer_out.txid = 10005
        transfer_out.withdraw_ids = withdraw_a.id.to_s + ",321"
        transfer_out.amount = withdraw_a.amount + 666
        transfer_out.save

        # reconcile withdrawal 1 not reconciled
        withdraw_remote = { "txid"=> "10005", "email"=> "abc@321.com", "customer_code"=> '5asdfds4', "withdraw_id"=> withdraw_a.id}
        response = {}
        expect(transfer_out.send("can_reconcile?")).to eq(true)
        expect(transfer_out.my_withdrawal?(withdraw_remote, response)).to eq(true)
        transfer_out.withdraw_reconcile(response)
        transfer_out = TransferOut.find(transfer_out.id)
        expect(response[:success]).to eq(true)
        expect(transfer_out.lodged_amount).to eq(withdraw_a.sum)
        expect(transfer_out.fee).to eq(withdraw_a.fee)
        expect(transfer_out.result).to eq(:unreconciled)
        expect(transfer_out.error_info).to eq("Missing withdraw: '[321]'")

        # reconcile withdrawal 2 return error
        withdraw_remote = { "txid"=> "10005", "email"=> "xxxxxxxx@321.com", "customer_code"=> '5asdfds4', "withdraw_id"=> withdraw_b.id}
        expect(transfer_out.send("can_reconcile?")).to eq(true)
        expect(transfer_out.my_withdrawal?(withdraw_remote, response)).to eq(false)
        expect(response[:success]).to eq(false)
        expect(response[:error]).to eq("customer email not match: [transfer-out: 'abc@321.com', withdraw: 'xxxxxxxx@321.com']")

        # reconcile withdrawal 2 return error
        response = {}
        withdraw_remote = { "txid"=> "10005", "email"=> "abc@321.com", "customer_code"=> '123fdsa', "withdraw_id"=> withdraw_b.id}
        expect(transfer_out.send("can_reconcile?")).to eq(true)
        expect(transfer_out.my_withdrawal?(withdraw_remote, response)).to eq(false)
        expect(response[:success]).to eq(false)
        expect(response[:error]).to eq("customer code not match: [transfer-out: '5asdfds4', withdraw: '123fdsa']")

      end

    end

  end

end
