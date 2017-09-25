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

    it "When from 5~8 days" do
      params = { "page_num"=>2, "per_page"=>5, "created_at"=>Time.now - 5.days}
      get :index, params: params
      json = JSON.parse(response.body)
      expect(json['count']).to eq(8)
      expect(json['data'].size).to eq(3)
    end

    it "When from 15~18 days" do
      params = { "page_num"=>2, "per_page"=>5, "created_at"=>Time.now - 15.days}
      get :index, params: params
      json = JSON.parse(response.body)
      expect(json['count']).to eq(0)
      expect(json['data'].size).to eq(0)
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

    it "When from 15~18 days" do
      params = { "page_num"=>2, "per_page"=>5, "created_at"=>Time.now - 15.days}
      get :export, params: params
      expect(response.content_type).to eq("text/csv")
      csv = response.body.split("\n")
      expect(csv.size).to eq(1)
    end

  end

  describe "get /payments/export filter test" do
    it "When before 15 days" do
      params = { "archive_before"=>Time.now - 15.days}
      get :archive, params: params
      json = JSON.parse(response.body)
      expect(response).to have_http_status(200)
      expect(json['archived']).to eq(7)
    end

    it "When before 5 days" do
      params = { "archive_before"=>Time.now - 5.days}
      get :archive, params: params
      json = JSON.parse(response.body)
      expect(response).to have_http_status(400)
      expect(json['base'][0]).to match(/Please select a date and only record/)
    end

  end

end
