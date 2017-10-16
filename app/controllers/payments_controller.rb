require_relative '../services/payment_import'
require_relative '../../config/fiat_config'
require_relative '../services/validation'

class PaymentsController < ApplicationController
  before_action :auth_member!
  before_action :set_payment, only: [:show, :update, :force_reconcile]
  CONFIG = Rails.application.config_for(:fiat)
  # POST /payments
  def import
    uploaded_io = params[:payments]
    if !uploaded_io || uploaded_io.tempfile.class != Tempfile
      json_response( { payments: ['no file uploaded']} , 400)
    elsif !params[:timezone] || ! (/^[+\-](0\d|1[0-2]):([0-5]\d)$/.match(params[:timezone]) )
      json_response( { timezone: ["no timezone or error format eg: '+03:00' "]} , 400)
    #elsif !params[:bank_account] || ! bank_accounts_include?(params[:bank_account])
    #  json_response( { bank_account: ["incorrect bank account: '#{params[:bank_account]}' "]} , 400)
    elsif !params[:source_type] || ! source_types_include?(params[:source_type])
      json_response( { source_type: ["source type undefined : '#{params[:source_type]}' "]} , 400)
    else
      success, result = Fiat::PaymentImport.new.importPayments(params)
      json_response(success ? {:result => result} : {:base => [result]}, success ? 200 : 400) 
    end
  end


  # GET /payments
  def index
    messages = valid_search_params
    if !messages || messages.size == 0
      search_payments
      count = @payments.size
      @payments = @payments.paginate(page: params[:page_num], per_page: search_params[:per_page])
      json_response({count: count, data: @payments})
    else
      json_response(messages, 400)
    end
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

  def force_reconcile
    Fiat::PaymentImport.new.force_reconcile(@payment)
  end

  def daily_sum
    Payment.get_daily_sum()
  end

  private

  def search_payments
    @payments = Payment.all.order(id: :desc)
    @payments = @payments.with_result(search_params[:result]) if search_params[:result]
    @payments = @payments.with_status(search_params[:status]) if search_params[:status]
    @payments = @payments.where('created_at > ? and created_at < ?', Time.zone.parse(search_params[:created_at]) - CONFIG["search_day_diff"].days,search_params[:created_at]) if search_params[:created_at]
  end

  def valid_search_params
  search_params.to_h.inject({}) do |messages, (k, v)|
      if v
        case k
        when "page_num"
          messages.merge(valid_integer(k, v))
        when "per_page"
          messages.merge(valid_integer(k, v))
        when "status"
          messages.merge(valid_string_in_array(["new", "sent", "archived"], k, v))
        when "result"
          messages.merge(valid_string_in_array(["unreconciled", "reconciled", "error"], k, v))
        when "created_at"
          messages.merge(valid_time(k, v))
        when "archive_before"
          messages.merge(valid_time(k, v))
        end
      end
    end
  end

  def valid_integer(name, integer)
    if integer.to_i > 0 then {} else {name.to_sym => ["#{name} should be Integer"]} end
  end

  def valid_string_in_array(array, name, string)
    if array.include?(string) then {} else {name.to_sym => ["#{name} should in #{array}"]} end
  end

  def valid_time(name, time)
    begin
      Time.zone.parse(time)
      return {}
    rescue ArgumentError=> e
      {name.to_sym => ["#{name} should be date time: #{time}"]}
    end
  end

  def source_types_include?(source_type)
    Fiat::FUND_TYPE.include?(source_type)
  end

  def bank_accounts_include?(bank_account)
    @@bank_accounts ||= FiatConfig.new[:bank_accounts]
    @@bank_accounts.inject(false) do |match, b|
      return match if match
      bank_account.keys.each do |key|
        if bank_account[key] == b[key]
          match = true
        else
          match = false
          break
        end
      end
      match
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
