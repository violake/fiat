require 'rails_helper'
require_relative "../spec_helper"

RSpec.describe BankServer do

  before(:all) { @bs = BankServer.new(FiatConfig.new["bank"], Logger.new(STDOUT)) }
  let!(:payments_data) { create_list(:payment, 10) }
  let(:payment_id) { payments_data.first.id }
  let(:deposit_remote) { {"deposit_id"=> "123",
                          "lodged_amount"=> "100.0",
                          "account_id"=> "234",
                          "member_id"=>"23",
                          "currency"=>"aud",
                          "amount"=>"150.0",
                          "aasm_state"=> "accepted",
                          "updated_at"=> "20170802123456",
                          "done_at"=> "20170901123456"} }
  let!(:deposit) { create(:accepted_deposit) }
  let!(:undone_deposit) { create(:submitting_deposit) }
  let(:rpc) { {"account_id"=> 5, "currency"=>"aud"} }

  describe 'autodeposit message comes' do

    it 'new accepted deposit, returns true' do
      result = @bs.autodeposit({"payment_id"=> payment_id,"deposit"=> deposit_remote})
      expect(result).not_to be_empty
      expect(result[:log]).to eq(true)
      expect(result[:success]).to eq(true)
      expect(result[:payment_id]).to eq(payment_id)
      expect(result[:deposit_id]).to eq(deposit_remote["deposit_id"])
      expect(Deposit.find(deposit_remote["deposit_id"]).aasm_state).to eq("accepted")
      expect(Payment.find(payment_id).result).to eq("reconciled")
      expect(Payment.find(payment_id).deposit_id).to eq(deposit_remote["deposit_id"].to_i)
    end

    it 'new submitting deposit, returns true' do
      deposit_remote["aasm_state"] = "submitting"
      deposit_remote["error"] = "amount > 2000"

      result = @bs.autodeposit({"payment_id"=> payment_id,"deposit"=> deposit_remote})
      expect(result).not_to be_empty
      expect(result[:success]).to eq(true)
      expect(result[:payment_id]).to eq(payment_id)      
      expect(result[:deposit_id]).to eq(deposit_remote["deposit_id"])
      expect(Deposit.find(deposit_remote["deposit_id"]).aasm_state).to eq("submitting")
      expect(Payment.find(payment_id).result).to eq("unreconciled")
      expect(Payment.find(payment_id).error_info).to eq("amount > 2000")
      expect(Payment.find(payment_id).deposit_id).to eq(deposit_remote["deposit_id"].to_i)
    end

    it 'submitting deposit change to accepted, returns true' do
      deposit_remote["deposit_id"] = undone_deposit.id
      result = @bs.autodeposit({"payment_id"=> payment_id,"deposit"=> deposit_remote})
      expect(result).not_to be_empty
      expect(result[:success]).to eq(true)
      expect(result[:payment_id]).to eq(payment_id)  
      expect(result[:deposit_id]).to eq(undone_deposit.id)
      expect(Deposit.find(undone_deposit.id).aasm_state).to eq("accepted")
      expect(Payment.find(payment_id).result).to eq("reconciled")
      expect(Payment.find(payment_id).deposit_id).to eq(undone_deposit.id)
    end

    it 'old accepted deposit, return false' do

      deposit_remote["deposit_id"] = deposit.id

      result = @bs.autodeposit({"payment_id"=> payment_id,"deposit"=> deposit_remote})
      expect(result).not_to be_empty
      expect(result[:log]).to eq(true)
      expect(result[:success]).to eq(false)
      expect(result[:payment_id]).to eq(payment_id)  
      expect(result[:deposit_id]).to eq(deposit.id)
      expect(result[:error]).to eq("deposit already done")
    end

    it 'invalid payment error, return true' do

      result = @bs.autodeposit({"payment_id"=> payment_id,"error"=> "wrong customer code: no such account"})
      expect(result).not_to be_empty
      expect(result[:success]).to eq(true)
      expect(result[:payment_id]).to eq(payment_id)
      expect(Payment.find(payment_id).error_info).to eq("wrong customer code: no such account")
    end
  end

  describe 'rpc call message comes' do
    it 'return code when call generate customer code with valid params' do
      customer_code = @bs.getcustomercode(rpc["account_id"])
      expect(customer_code).not_to be_empty
      expect(customer_code).to eq("51")
    end

    it 'raise CodecalRPCError when call generate customer code with invalid params' do
      expect { @bs.getcustomercode("fdsa") }.to raise_error(CodecalRPCError)
    end

    it 'return json(valid:true) when call validate customer code with valid params' do
      rpc["customer_code"]="26"
      rpc["account_id"]="2"
      result = @bs.validatecustomercode(rpc["customer_code"], rpc["account_id"])
      expect(result).not_to be_empty
      expect(result[:isvalid]).to eq(true)
      expect(result[:ismine]).to eq(true)
    end

    it 'return json(valid:false) when call validate customer code with invalid params' do
      rpc["customer_code"]="52"
      result = @bs.validatecustomercode(rpc["customer_code"], rpc["account_id"])
      expect(result).not_to be_empty
      expect(result[:isvalid]).to eq(false)
      expect(result[:ismine]).to eq(false)
    end
  end
end