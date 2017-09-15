require 'rails_helper'
require_relative "../spec_helper"

RSpec.describe BankServer do

  before(:all) { @bs = BankServer.new(FiatConfig.new["bank"], Logger.new(STDOUT), "bank") }
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
  

  # Test suite for GET /payments
  describe 'deposit message comes' do

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
end