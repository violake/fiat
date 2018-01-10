require 'rails_helper'
require './app/services/transaction_import.rb'

RSpec.describe TransferIn, type: :model do
  let(:transfer) { create(:bank) }
  let(:transactionImport) { }
  let(:bank) { {created_at: "201708010100"} }

  it { should validate_presence_of(:source_id) }
  it { should validate_presence_of(:source_name) }
  it { should validate_presence_of(:source_code) }
  it { should validate_presence_of(:transfer_type) }
  it { should validate_presence_of(:amount) }
  it { should validate_presence_of(:currency) }
  it { should validate_uniqueness_of(:source_id).scoped_to(:source_code)  }
  it { should validate_uniqueness_of(:txid) }

  describe "convert timezone for bank" do

    it "do not convert when error timezone given" do
      ts = Fiat::TransactionImport.new 

      response = ts.set_timezone("+15:00")
      expect(Time.zone.utc_offset).to eq(0)
      expect(response).to eq("+15:00")

      response = ts.set_timezone("fdsa")
      expect(Time.zone.utc_offset).to eq(0)
      expect(response).to eq("fdsa")
    end

    it "convert when timezone(-) given" do
      ts = Fiat::TransactionImport.new 
      params = {
                source_id: 1, 
                source_name: "f", 
                source_code: "s", 
                transfer_type: "Bank",
                amount: "123",
                currency: "aud",
                description: "5423jkl",
                created_at: "201708010100",
                updated_at: "201708010300"
               }
      ts.set_timezone("-03:00")
      expect(Time.zone.utc_offset).to eq(-10800)
      transfer.set_values(params)
      expect(transfer.created_at).to eq("2017-08-01 04:00:00 UTC")
      expect(transfer.updated_at).to eq("2017-08-01 06:00:00 UTC")
      ts.timezone_reset
      expect(Time.zone.utc_offset).to eq(0)
    end

    it "convert when timezone(+) given" do
      ts = Fiat::TransactionImport.new 
      params = {
                source_id: 1, 
                source_name: "f", 
                source_code: "s", 
                transfer_type: "Bank",
                amount: "123",
                currency: "aud",
                description: "5423jkl",
                created_at: "201708010100",
                updated_at: "201708010300"
               }
      ts.set_timezone("+03:00")
      expect(Time.zone.utc_offset).to eq(10800)
      transfer.set_values(params)
      expect(transfer.created_at).to eq("2017-07-31 22:00:00 UTC")
      expect(transfer.updated_at).to eq("2017-08-01 00:00:00 UTC")
      ts.timezone_reset
      expect(Time.zone.utc_offset).to eq(0)
    end

    it "do not convert when it has own timezone" do

    end 

    it "do not convert when timezone is local" do

    end
  end

  describe "capture customer code" do
    it "return correct code when one code given" do
      bank[:description] = "Direct Credit Go MEACHAM 3c3k37"
      transfer.set_values(bank)
      expect(transfer.customer_code).to eq("3c3k37")
    end

    it "return correct upcase code when one code given" do
      bank[:description] = "Direct Credit Go MEACHAM 3C3K37"
      transfer.set_values(bank)
      expect(transfer.customer_code).to eq("3c3k37")
    end

    it "return correct code when one correct code and one error code given" do
      bank[:description] = "Direct Credit Go MEACHAM 3d2343 3c3k37"
      transfer.set_values(bank)
      expect(transfer.customer_code).to eq("3c3k37")

      bank[:description] = "Direct Credit Go MEACHAM 3c3k37 3d2343"
      transfer.set_values(bank)
      expect(transfer.customer_code).to eq("3c3k37")
    end

    it "return nil when error code given" do
      bank[:description] = "Direct Credit Go MEACHAM 3d2343"
      transfer.set_values(bank)
      expect(transfer.customer_code).to eq(nil)

      bank[:description] = "Direct Credit Go MEACHAM 3d2343 6flkjdfha"
      transfer.set_values(bank)
      expect(transfer.customer_code).to eq(nil)
    end
  end

end
