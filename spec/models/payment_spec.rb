require 'rails_helper'

RSpec.describe Payment, type: :model do
  let(:payment) { create(:bank) }
  let(:bank) { {created_at: "201708010100"} }

  it { should validate_presence_of(:source_id) }
  it { should validate_presence_of(:source_name) }
  it { should validate_presence_of(:source_code) }
  it { should validate_presence_of(:payment_type) }
  it { should validate_presence_of(:amount) }
  it { should validate_presence_of(:currency) }
  it { should validate_uniqueness_of(:source_id).scoped_to(:source_code)  }
  it { should validate_uniqueness_of(:txid) }

  describe "convert timezone for bank" do
    it "convert when timezone(-) given" do
      params = {
                source_id: 1, 
                source_name: "f", 
                source_code: "s", 
                payment_type: "Bank",
                amount: "123",
                currency: "aud",
                description: "5423jkl",
                created_at: "201708010100",
                updated_at: "201708010300"
               }
      Payment.set_timezone("-03:00")
      expect(Time.zone.utc_offset).to eq(-10800)
      payment.set_values(params)
      expect(payment.created_at).to eq("2017-08-01 04:00:00 UTC")
      expect(payment.updated_at).to eq("2017-08-01 06:00:00 UTC")
      Payment.timezone_reset
      expect(Time.zone.utc_offset).to eq(0)
    end

    it "convert when timezone(+) given" do
      params = {
                source_id: 1, 
                source_name: "f", 
                source_code: "s", 
                payment_type: "Bank",
                amount: "123",
                currency: "aud",
                description: "5423jkl",
                created_at: "201708010100",
                updated_at: "201708010300"
               }
      Payment.set_timezone("+03:00")
      expect(Time.zone.utc_offset).to eq(10800)
      payment.set_values(params)
      expect(payment.created_at).to eq("2017-07-31 22:00:00 UTC")
      expect(payment.updated_at).to eq("2017-08-01 00:00:00 UTC")
      Payment.timezone_reset
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
      payment.set_values(bank)
      expect(payment.customer_code).to eq("3c3k37")
    end

    it "return correct upcase code when one code given" do
      bank[:description] = "Direct Credit Go MEACHAM 3C3K37"
      payment.set_values(bank)
      expect(payment.customer_code).to eq("3c3k37")
    end

    it "return correct code when one correct code and one error code given" do
      bank[:description] = "Direct Credit Go MEACHAM 3d2343 3c3k37"
      payment.set_values(bank)
      expect(payment.customer_code).to eq("3c3k37")

      bank[:description] = "Direct Credit Go MEACHAM 3c3k37 3d2343"
      payment.set_values(bank)
      expect(payment.customer_code).to eq("3c3k37")
    end

    it "return nil when error code given" do
      bank[:description] = "Direct Credit Go MEACHAM 3d2343"
      payment.set_values(bank)
      expect(payment.customer_code).to eq(nil)

      bank[:description] = "Direct Credit Go MEACHAM 3d2343 6flkjdfha"
      payment.set_values(bank)
      expect(payment.customer_code).to eq(nil)
    end
  end

end
