require 'rails_helper'

RSpec.describe PaymentsController, type: :controller do
  let!(:new_payments) { create_list(:new_payment, 10) }
  let!(:error_payments) { create_list(:error_payment, 3) }
  let!(:reconciled_payments) { create_list(:reconciled_payment, 7) }
  let!(:unreconciled_payments) { create_list(:unreconciled_payment, 5) }

  describe "get /payments paginate and filter test" do
    
    it "When no paginate or filter" do
      get :index
      json = JSON.parse(response.body)
      expect(json['count']).to eq(25)
      expect(json['data'].size).to eq(25)
    end

    it "When paginate" do
      params = { "page_num"=>2, "per_page"=>20 }
      get :index, params: params
      json = JSON.parse(response.body)
      expect(json['count']).to eq(25)
      expect(json['data'].size).to eq(5)
    end

    it "When paginate and status = new" do
      params = { "page_num"=>2, "per_page"=>10, "status"=>"new"}
      get :index, params: params
      json = JSON.parse(response.body)
      expect(json['count']).to eq(13)
      expect(json['data'].size).to eq(3)
    end

    it "When paginate and status = new and result = error" do
      params = { "page_num"=>2, "per_page"=>10, "status"=>"new", "result"=>"error"}
      get :index, params: params
      json = JSON.parse(response.body)
      expect(json['count']).to eq(3)
      expect(json['data'].size).to eq(0)
    end

    it "When status = sent and result = reconciled" do
      params = { "page_num"=>2, "per_page"=>5, "status"=>"sent", "result"=>"reconciled"}
      get :index, params: params
      json = JSON.parse(response.body)
      expect(json['count']).to eq(7)
      expect(json['data'].size).to eq(2)
    end
  end

  describe "get /payments/export filter test" do

    it "When status = new and result = error" do
      params = { "status"=>"new", "result"=>"error" }
      get :export, params: params
      expect(response.content_type).to eq("text/csv")
      csv = response.body.split("\n")
      expect(csv.size).to eq(4)
    end

    it "When status = new and result = error" do
      params = { "status"=>"sent", "result"=>"unreconciled" }
      get :export, params: params
      expect(response.content_type).to eq("text/csv")
      csv = response.body.split("\n")
      expect(csv.size).to eq(6)
    end

  end
end
