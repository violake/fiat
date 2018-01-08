require 'rails_helper'

RSpec.describe 'Payments API', type: :request do

  let!(:payments_data) { create_list(:payment, 10) }
  let(:payment_id) { payments_data.first.id }

  before {
    get '/fake_session'
  }
  # Test suite for GET /payments
  describe 'GET /payments' do
    # make HTTP get request before each example
    before { get '/payments' }

    it 'returns payments' do
      # Note `json` is a custom helper to parse JSON responses
      expect(json).not_to be_empty
      expect(json["data"].size).to eq(10)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /payments/:id
  describe 'GET /payments/:id' do
    before { get "/payments/#{payment_id}" }

    context 'when the record exists' do
      it 'returns the payment' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(payment_id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let(:payment_id) { 99999 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Payment/)
      end
    end
  end


  # POST /payments

  describe 'POST /payments correct Beyond payments' do
    let(:payments) { { payments:  Rack::Test::UploadedFile.new(Rails.root.join("spec/factories/Beyond_statement_normal.csv")), timezone: "+11:00", bank_account: "805022-03651883"  } }

    before {post '/payments', params: payments}

    it "returns result of import" do
      expect(json['result']['imported']).to eq(12)
      expect(json['result']['ignored']).to eq(0)
      expect(json['result']['error']).to eq(2)
      expect(json['result']['sent']).to eq(10)
    end

    it "returns status code 204" do
      expect(response).to have_http_status(200)
    end
  end

  describe 'POST /payments correct payments' do
    let(:payments) { { payments:  Rack::Test::UploadedFile.new(Rails.root.join("spec/factories/payments_with_header.csv")), timezone: "+08:00", bank_account: "111111-222222" } }

    before {post '/payments', params: payments}

    it "returns result of import" do
      expect(json['result']['imported']).to eq(3)
      expect(json['result']['ignored']).to eq(0)
      expect(json['result']['error']).to eq(2)
      expect(json['result']['sent']).to eq(1)
      expect(Payment.with_status(:sent).size).to eq(1)
    end

    it "returns status code 200" do
      expect(response).to have_http_status(200)
    end
  end

  describe 'POST /Payments no colname ' do
    let(:payments) { { payments:  Rack::Test::UploadedFile.new(Rails.root.join("spec/factories/payments_no_colname.csv")), timezone: "+08:00", bank_account: "111111-222222" } }

    before {post '/payments', params: payments}

    it "returns result of import" do
      expect(json['base'][0]).to match(/Import failed: column missing /)
    end

    it "returns status code 400" do
      expect(response).to have_http_status(400)
    end
  end

  describe 'POST /Payments no file ' do
    before {post '/payments', params: {timezone: "+08:00"} }

    it "returns result of import" do
      expect(json['payments'][0]).to match(/no file uploaded/)
    end

    it "returns status code 400" do
      expect(response).to have_http_status(400)
    end
  end

  describe 'POST /Payments wrong filetype ' do
    let(:payments) { { payments:  Rack::Test::UploadedFile.new(Rails.root.join("spec/factories/bank.rb")), timezone: "+08:00", bank_account: "111111-222222" } }
    before {post '/payments', params: payments}

    it "returns result of import" do
      expect(json['base'][0]).to match(/Error Type of File:/)
    end

    it "returns status code 400" do
      expect(response).to have_http_status(400)
    end
  end

  describe 'POST /Payments no timezone ' do
    let(:payments) { { payments:  Rack::Test::UploadedFile.new(Rails.root.join("spec/factories/bank.rb")) } }
    before {post '/payments', params: payments }

    it "returns result of import" do
      expect(json['timezone'][0]).to match(/no timezone or error format eg/)
    end

    it "returns status code 400" do
      expect(response).to have_http_status(400)
    end
  end

  describe 'POST /Payments error timezone ' do
    let(:payments) { { payments:  Rack::Test::UploadedFile.new(Rails.root.join("spec/factories/bank.rb")), timezone: "28:00", bank_account: "111111-222222" } }
    before {post '/payments', params: payments }

    it "returns result of import" do
      expect(json['timezone'][0]).to match(/no timezone or error format/)
    end

    it "returns status code 400" do
      expect(response).to have_http_status(400)
    end
  end

  describe 'POST /Payments no bank account ' do
    let(:payments) { { payments:  Rack::Test::UploadedFile.new(Rails.root.join("spec/factories/bank.rb")), timezone: "-10:00"} }
    before {post '/payments', params: payments }    

    it "returns result of import" do
      expect(json['bank_account'][0]).to match(/no bank account or error/)
    end

    it "returns status code 400" do
      expect(response).to have_http_status(400)
    end
  end



  describe 'POST /Payments, modify wrong status ' do
    let(:payments) { { payments:  Rack::Test::UploadedFile.new(Rails.root.join("spec/factories/payments_with_header.csv")), timezone: "+08:00", bank_account: "111111-222222" } }

    before {post '/payments', params: payments}

    it "returns result of import reconciled payment and update unreconciled payment" do
      p = Payment.find_by(source_id:"06332152347234", source_code: "import_code3")
      p.result = 'reconciled'
      p.save

      p_changed = Payment.find_by(source_id:"06398010987329", source_code: "import_code1")
      p_changed.description = "new one"
      p_changed.result = "unreconciled"
      p_changed.save

      post '/payments', params: payments

      expect(json['result']['imported']).to eq(2)
      expect(json['result']['ignored']).to eq(1)
      expect(json['result']['error']).to eq(2)
      expect(json['result']['sent']).to eq(0)
      expect(response).to have_http_status(200)
      p_result = Payment.find_by(source_id:"06398010987329", source_code: "import_code1")
      expect(p_result.result).to eq("error")
      expect(p_result.description).to eq("net bank transfer, id:107")
      
    end


    it "returns result of import sent payment" do
      p = Payment.find_by(source_id:"06398010987329", source_code: "import_code1")
      p.status = 'sent'
      p.result = 'unreconciled'
      p.save

      post '/payments', params: payments

      expect(json['result']['imported']).to eq(1)
      expect(json['result']['ignored']).to eq(2)
      expect(json['result']['error']).to eq(1)
      expect(json['result']['sent']).to eq(0)
      expect(response).to have_http_status(200)
      
    end

    it "returns result of import sent error payment" do
      p = Payment.find_by(source_id:"06332152347234", source_code: "import_code3")
      p.status = 'sent'
      p.result = 'error'
      p.error_info = 'custoer code error'
      p.save

      post '/payments', params: payments

      expect(json['result']['imported']).to eq(3)
      expect(json['result']['ignored']).to eq(0)
      expect(json['result']['error']).to eq(2)
      expect(json['result']['sent']).to eq(1)
      expect(response).to have_http_status(200)
      p_result = Payment.find_by(source_id:"06332152347234", source_code: "import_code3")
      expect(p_result.error_info).to eq(nil)
      
    end
  end

  # Test suite for PUT /deposits/:id
  describe 'PUT /payments/:id' do
    let(:valid_attributes) { { account_id: 17, member_id: 27, currency: "aud", lodged_amount: "108", aasm_state:"submitting" } }

    context 'when the record exists' do
      before { put "/payments/#{payment_id}", params: valid_attributes }

      it 'updates the record' do
        expect(response.body).to be_empty
      end

      it 'returns status code 204' do
        expect(response).to have_http_status(204)
      end
    end
  end
end