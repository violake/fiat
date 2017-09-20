require_relative '../services/payment_import'

class PaymentsController < ApplicationController
  before_action :set_payment, only: [:show, :update]
  # POST /payments
  def import
    uploaded_io = params[:payments]
    if uploaded_io.tempfile.class != Tempfile
      render json: {errors: 'no file uploaded'}, status: 400 
    end

    success, result = Fiat::PaymentImport.new.importPayments(uploaded_io.tempfile)
    json_response(success ? {:result => result} : {:error => result}, success ? 200 : 400)
  end

  # GET /payments
  def index
    @payments = Payment.all.order(id: :desc)
    @payments = @payments.with_result(params[:result]) if params[:result]
    @payments = @payments.with_status(params[:status]) if params[:status]
    count = @payments.size
    @payments = @payments.paginate(page: params[:page_num], per_page: params[:per_page]) if params[:page_num] && params[:per_page]
    json_response({count: count, data: @payments})
  end

  def export
    @payments = Payment.all.order(id: :desc)
    @payments = @payments.with_result(params[:result]) if params[:result]
    @payments = @payments.with_status(params[:status]) if params[:status]
    csv = @payments.to_csv
    send_data csv, filename: "payments-#{Time.now.strftime('%Y%m%d_%H%M%S')}.csv"

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

  def payment_params
    # whitelist params
    params.permit(:source_id, :source_name, :source_code, :payment_type, :amount, :customer_code, :currency, :result, :description, :sender_info)
  end

  def set_payment
    @payment = Payment.find(params[:id])
  end
end
