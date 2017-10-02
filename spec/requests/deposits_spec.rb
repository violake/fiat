require 'rails_helper'

RSpec.describe 'Deposits API', type: :request do
  # initialize test data 
  let!(:deposits) { create_list(:deposit, 10) }
  let(:deposit_id) { deposits.first.id }

  before {
    get '/fake_session'
  }
  # Test suite for GET /deposits
  describe 'GET /deposits' do
    # make HTTP get request before each example
    before { get '/deposits' }

    it 'returns deposits' do
      # Note `json` is a custom helper to parse JSON responses
      expect(json).not_to be_empty
      expect(json.size).to eq(10)
    end

    it 'returns status code 200' do
      expect(response).to have_http_status(200)
    end
  end

  # Test suite for GET /deposits/:id
  describe 'GET /deposits/:id' do
    before { get "/deposits/#{deposit_id}" }

    context 'when the record exists' do
      it 'returns the deposit' do
        expect(json).not_to be_empty
        expect(json['id']).to eq(deposit_id)
      end

      it 'returns status code 200' do
        expect(response).to have_http_status(200)
      end
    end

    context 'when the record does not exist' do
      let(:deposit_id) { 99999 }

      it 'returns status code 404' do
        expect(response).to have_http_status(404)
      end

      it 'returns a not found message' do
        expect(response.body).to match(/Couldn't find Deposit/)
      end
    end
  end

=begin
  # Test suite for POST /deposits
  describe 'POST /deposits' do
    # valid payload
    let(:valid_attributes) { { account_id: 17, member_id: 27, currency: "aud", lodged_amount: "108", aasm_state:"submitting" } }

    context 'when the request is valid' do
      before { post '/deposits', params: valid_attributes }

      it 'creates a deposit' do
        expect(json['account_id']).to eq(17)
        expect(json['lodged_amount']).to eq('108.0')
      end

      it 'returns status code 201' do
        expect(response).to have_http_status(201)
      end
    end

    context 'when the request is invalid' do
      before { post '/deposits', params: { account_id: '123' } }

      it 'returns status code 422' do
        expect(response).to have_http_status(422)
      end

      it 'returns a validation failure message' do
        expect(response.body)
          .to match(/Validation failed: Member can't be blank/)
      end
    end
  end

  # Test suite for PUT /deposits/:id
  describe 'PUT /deposits/:id' do
    let(:valid_attributes) { { account_id: 17, member_id: 27, currency: "aud", lodged_amount: "108", aasm_state:"submitting" } }

    context 'when the record exists' do
      before { put "/deposits/#{deposit_id}", params: valid_attributes }

      it 'updates the record' do
        expect(response.body).to be_empty
      end

      it 'returns status code 204' do
        expect(response).to have_http_status(204)
      end
    end
  end

  # Test suite for DELETE /deposits/:id
  describe 'DELETE /deposits/:id' do
    before { delete "/deposits/#{deposit_id}" }

    it 'returns status code 204' do
      expect(response).to have_http_status(204)
    end
  end
=end
end