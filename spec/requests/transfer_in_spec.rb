require 'rails_helper'

RSpec.describe 'TransferIns API', type: :request do

  let!(:transfers_data) { create_list(:transfer_in, 10) }
  let(:transfer_id) { transfers_data.first.id }

  before {
    get '/fake_session'
  }
  # Test suite for GET /transfer_ins
  describe 'GET /transfer_ins' do
    # make HTTP get request before each example
    before { get '/transfer_ins' }

    it 'returns transfers' do
      # Note `json` is a custom helper to parse JSON responses
      expect(json).not_to be_empty
      expect(json["data"].size).to eq(10)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /transfer_ins/:id
  describe 'GET /transfer_ins/:id' do
    before { get "/transfer_ins/#{transfer_id}" }

    context 'when the record exists' do
      it 'returns the transfer' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(transfer_id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let(:transfer_id) { 99999 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Transfer/)
      end
    end
  end


  # POST /transfer_ins

  describe 'POST /transfer_ins correct Beyond transfers' do
    let(:transfers) { { transfers:  Rack::Test::UploadedFile.new(Rails.root.join("spec/factories/Beyond_statement_normal.csv")), timezone: "+11:00", bank_account: "805022-03651883"  } }

    before {post '/transfer_ins', params: transfers}

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

  describe 'POST /transfer_ins correct transfers' do
    let(:transfers) { { transfers:  Rack::Test::UploadedFile.new(Rails.root.join("spec/factories/transfer_ins_with_header.csv")), timezone: "+08:00", bank_account: "111111-222222" } }

    before {post '/transfer_ins', params: transfers}

    it "returns result of import" do
      expect(json['result']['imported']).to eq(3)
      expect(json['result']['ignored']).to eq(0)
      expect(json['result']['error']).to eq(2)
      expect(json['result']['sent']).to eq(1)
      expect(TransferIn.with_status(:sent).size).to eq(1)
    end

    it "returns status code 200" do
      expect(response).to have_http_status(200)
    end
  end

  describe 'POST /transfer_ins no colname ' do
    let(:transfers) { { transfers:  Rack::Test::UploadedFile.new(Rails.root.join("spec/factories/transfer_ins_no_colname.csv")), timezone: "+08:00", bank_account: "111111-222222" } }

    before {post '/transfer_ins', params: transfers}

    it "returns result of import" do
      expect(json['base'][0]).to match(/Import failed: column missing /)
    end

    it "returns status code 400" do
      expect(response).to have_http_status(400)
    end
  end

  describe 'POST /transfer_ins no file ' do
    before {post '/transfer_ins', params: {timezone: "+08:00"} }

    it "returns result of import" do
      expect(json['transfers'][0]).to match(/no file uploaded/)
    end

    it "returns status code 400" do
      expect(response).to have_http_status(400)
    end
  end

  describe 'POST /transfer_ins wrong filetype ' do
    let(:transfers) { { transfers:  Rack::Test::UploadedFile.new(Rails.root.join("spec/factories/bank.rb")), timezone: "+08:00", bank_account: "111111-222222" } }
    before {post '/transfer_ins', params: transfers}

    it "returns result of import" do
      expect(json['base'][0]).to match(/Error Type of File:/)
    end

    it "returns status code 400" do
      expect(response).to have_http_status(400)
    end
  end

  describe 'POST /transfer_ins no timezone ' do
    let(:transfers) { { transfers:  Rack::Test::UploadedFile.new(Rails.root.join("spec/factories/bank.rb")) } }
    before {post '/transfer_ins', params: transfers }

    it "returns result of import" do
      expect(json['timezone'][0]).to match(/no timezone or error format eg/)
    end

    it "returns status code 400" do
      expect(response).to have_http_status(400)
    end
  end

  describe 'POST /transfer_ins error timezone ' do
    let(:transfers) { { transfers:  Rack::Test::UploadedFile.new(Rails.root.join("spec/factories/bank.rb")), timezone: "28:00", bank_account: "111111-222222" } }
    before {post '/transfer_ins', params: transfers }

    it "returns result of import" do
      expect(json['timezone'][0]).to match(/no timezone or error format/)
    end

    it "returns status code 400" do
      expect(response).to have_http_status(400)
    end
  end

  describe 'POST /transfer_ins no bank account ' do
    let(:transfers) { { transfers:  Rack::Test::UploadedFile.new(Rails.root.join("spec/factories/bank.rb")), timezone: "-10:00"} }
    before {post '/transfer_ins', params: transfers }    

    it "returns result of import" do
      expect(json['bank_account'][0]).to match(/no bank account or error/)
    end

    it "returns status code 400" do
      expect(response).to have_http_status(400)
    end
  end



  describe 'POST /transfer_ins, modify wrong status ' do
    let(:transfers) { { transfers:  Rack::Test::UploadedFile.new(Rails.root.join("spec/factories/transfer_ins_with_header.csv")), timezone: "+08:00", bank_account: "111111-222222" } }

    before {post '/transfer_ins', params: transfers}

    it "returns result of import reconciled transfer and update unreconciled transfer" do
      p = TransferIn.find_by(source_id:"06332152347234", source_code: "import_code3")
      p.result = 'reconciled'
      p.save

      p_changed = TransferIn.find_by(source_id:"06398010987329", source_code: "import_code1")
      p_changed.description = "new one"
      p_changed.result = "unreconciled"
      p_changed.save

      post '/transfer_ins', params: transfers

      expect(json['result']['imported']).to eq(2)
      expect(json['result']['ignored']).to eq(1)
      expect(json['result']['error']).to eq(2)
      expect(json['result']['sent']).to eq(0)
      expect(response).to have_http_status(200)
      p_result = TransferIn.find_by(source_id:"06398010987329", source_code: "import_code1")
      expect(p_result.result).to eq("error")
      expect(p_result.description).to eq("net bank transfer, id:107")
      
    end


    it "returns result of import sent transfer" do
      p = TransferIn.find_by(source_id:"06398010987329", source_code: "import_code1")
      p.status = 'sent'
      p.result = 'unreconciled'
      p.save

      post '/transfer_ins', params: transfers

      expect(json['result']['imported']).to eq(1)
      expect(json['result']['ignored']).to eq(2)
      expect(json['result']['error']).to eq(1)
      expect(json['result']['sent']).to eq(0)
      expect(response).to have_http_status(200)
      
    end

    it "returns result of import sent error transfer" do
      p = TransferIn.find_by(source_id:"06332152347234", source_code: "import_code3")
      p.status = 'sent'
      p.result = 'error'
      p.error_info = 'custoer code error'
      p.save

      post '/transfer_ins', params: transfers

      expect(json['result']['imported']).to eq(3)
      expect(json['result']['ignored']).to eq(0)
      expect(json['result']['error']).to eq(2)
      expect(json['result']['sent']).to eq(1)
      expect(response).to have_http_status(200)
      p_result = TransferIn.find_by(source_id:"06332152347234", source_code: "import_code3")
      expect(p_result.error_info).to eq(nil)
      
    end
  end

  # Test suite for PUT /deposits/:id
  describe 'PUT /transfer_ins/:id' do
    let(:valid_attributes) { { account_id: 17, member_id: 27, currency: "aud", lodged_amount: "108", aasm_state:"submitting" } }

    context 'when the record exists' do
      before { put "/transfer_ins/#{transfer_id}", params: valid_attributes }

      it 'updates the record' do
        expect(response.body).to be_empty
      end

      it 'returns status code 204' do
        expect(response).to have_http_status(204)
      end
    end
  end
end
