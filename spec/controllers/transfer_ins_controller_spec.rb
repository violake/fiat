require 'rails_helper'

RSpec.describe TransferInsController, type: :controller do
  let!(:new_transfers) { create_list(:new_transfer, 10) }
  let!(:error_transfers) { create_list(:error_transfer, 3) }
  let!(:reconciled_transfers) { create_list(:reconciled_transfer, 7) }
  let!(:unreconciled_transfers) { create_list(:unreconciled_transfer, 5) }

  before {
    session[:member_id] = 2
  }

  describe "get /transfers paginate and filter test" do
    
    it "When no paginate or filter" do
      get :index
      json = JSON.parse(response.body)
      expect(json['count']).to eq(25)
      expect(json['data'].size).to eq(25)
    end

    it "When error paginate or filter" do
      params = { "page_num"=>0, "per_page"=>"fds" }
      get :index, params: params
      json = JSON.parse(response.body)
      expect(json['page_num'][0]).to match(/page_num should be Integer/)
      expect(json['per_page'][0]).to match(/per_page should be Integer/)
      expect(json.size).to eq(2)
      expect(response).to have_http_status(400)
    end

    it "When error created_at" do
      params = { "page_num"=>1, "per_page"=>10, "created_at"=>"20170733" }
      get :index, params: params
      json = JSON.parse(response.body)
      expect(json['created_at'][0]).to match(/created_at should be date ti/)
      expect(json.size).to eq(1)
      expect(response).to have_http_status(400)
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

  describe "get /transfers/export filter test" do

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

  describe "get /transfers/export filter test" do
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
