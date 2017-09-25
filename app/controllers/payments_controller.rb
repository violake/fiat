require_relative '../services/payment_import'
require_relative '../../config/fiat_config'

class PaymentsController < ApplicationController
  before_action :set_payment, only: [:show, :update]
  #before_action :auth_member!
  CONFIG = Rails.application.config_for(:fiat)
  # POST /payments
  def import
    uploaded_io = params[:payments]
    if !uploaded_io || uploaded_io.tempfile.class != Tempfile
      json_response( { payments: ['no file uploaded']} , 400)
    elsif !params[:timezone] || ! (/^[+\-](0\d|1[0-2]):([0-5]\d)$/.match(params[:timezone]) )
      json_response( { timezone: ["no timezone or error format eg: '+03:00' "]} , 400)
    else
      success, result = Fiat::PaymentImport.new.importPayments(uploaded_io.tempfile, params[:timezone])
      json_response(success ? {:result => result} : {:base => [result]}, success ? 200 : 400) 
    end
  end

  # GET /payments
  def index
    search_payments
    count = @payments.size
    @payments = @payments.paginate(page: params[:page_num], per_page: search_params[:per_page]) if search_params[:page_num] && search_params[:per_page]
    json_response({count: count, data: @payments})
  end

  def export
    search_payments
    csv = @payments.to_csv
    send_data csv, filename: "payments-#{Time.now.strftime('%Y%m%d_%H%M%S')}.csv"
  end

  def archive
    if search_params[:archive_before] && Time.zone.parse(search_params[:archive_before]) < Time.zone.now - CONFIG["archive_limit"].days
      @payments = Payment.with_status(:sent).where('created_at < ?', search_params[:archive_before]).each { |payment| payment.archive!}
      json_response( {archived: @payments.size}, 200)
    else
      json_response( {base: ["Please select a date and only record which is #{CONFIG["archive_limit"]} days before can be archived"]}, 400 )
    end
  end

  # GET /payments/:id
  def show
    json_response(@payment)
  end

  # PUT /payments/:id
  def update
    @payment.update(payment_params)
    head :no_content
  end

  private

  def search_payments
    @payments = Payment.all.order(id: :desc)
    @payments = @payments.with_result(search_params[:result]) if search_params[:result]
    @payments = @payments.with_status(search_params[:status]) if search_params[:status]
    if search_params[:created_at] && Time.zone.parse(search_params[:created_at])
      @payments = @payments.where('created_at > ? and created_at < ?', Time.zone.parse(search_params[:created_at]) - CONFIG["search_day_diff"].days,search_params[:created_at])
    end
  end

  def payment_params
    # whitelist params
    params.permit(:source_id, :source_name, :source_code, :payment_type, :amount, :customer_code, :currency, :result, :description, :sender_info)
  end

  def search_params
    # whitelist params
    params.permit(:source_id, :status, :result, :created_at, :archive_before, :per_page, :page_num)
  end

  def set_payment
    @payment = Payment.find(params[:id])
  end
end
