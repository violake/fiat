require_relative '../services/transfer_in_import'
require_relative '../../config/fiat_config'
require_relative '../services/validation'

class TransferInsController < ApplicationController
  before_action :auth_member!
  before_action :set_transfer, only: [:show, :update, :force_reconcile]
  before_action :validate_import_params, only: [:import]

  CONFIG = FiatConfig.new
  # POST /transfers
  def import
    success, result = Fiat::TransferInImport.new.importTransferIns(params)
    json_response(success ? {:result => result} : {:base => [result]}, success ? 200 : 400)
  end


  # GET /transfers
  def index
    messages = valid_search_params
    if !messages || messages.size == 0
      search_transfers
      count = @transfers.size
      @transfers = @transfers.paginate(page: params[:page_num], per_page: search_params[:per_page])
      json_response({count: count, data: @transfers})
    else
      json_response(messages, 400)
    end
  end

  def export
    search_transfers
    csv = @transfers.to_csv
    send_data csv, filename: "transfers-#{Time.now.strftime('%Y%m%d_%H%M%S')}.csv"
  end

  def archive
    if search_params[:archive_before] && Time.zone.parse(search_params[:archive_before]) < Time.zone.now - CONFIG[:fiat][:archive_limit].days
      @transfers = TransferIn.with_status(:sent).where('created_at < ?', search_params[:archive_before]).each { |transfer| transfer.archive!}
      json_response( {archived: @transfers.size}, 200)
    else
      json_response( {base: ["Please select a date and only record which is #{CONFIG[:fiat][:archive_limit]} days before can be archived"]}, 400 )
    end
  end

  # GET /transfers/:id
  def show
    json_response(@transfer)
  end

  # PUT /transfers/:id
  def update
    @transfer.update(transfer_params)
    head :no_content
  end

  def force_reconcile
    Fiat::TransferInImport.new.force_reconcile(@transfer)
  end

  def daily_sum
    TransferIn.get_daily_sum()
  end

  private

  def search_transfers
    @transfers = TransferIn.all.order(id: :desc)
    @transfers = @transfers.with_result(search_params[:result]) if search_params[:result]
    @transfers = @transfers.with_status(search_params[:status]) if search_params[:status]
    transfers_date_inteval(Time.zone.parse(search_params[:created_at]) - CONFIG[:fiat][:search_day_diff].days, search_params[:created_at]) if search_params[:created_at]
  end

  def transfers_date_inteval(start_at, end_at)
    @transfers = @transfers.where('created_at > ? and created_at < ?', start_at, end_at)
  end

  def validate_import_params
    uploaded_io = params[:transfers]
    
    if !uploaded_io || uploaded_io.tempfile.class != Tempfile
      json_response( { transfers: ['no file uploaded']} , 400)
    elsif !params[:timezone] || ! (/^[+\-](0\d|1[0-2]):([0-5]\d)$/.match(params[:timezone]) )
      json_response( { timezone: ["no timezone or error format eg: '+03:00' "]} , 400)
    elsif !params[:bank_account]
      json_response( { bank_account: ["no bank account or error "]} , 400)
    else
      bank_account = get_bankaccount(params[:bank_account], params)
      if bank_account
        params[:bank_account] = bank_account
        params[:source_type] = bank_account["bank"].split(' ').shift.downcase
      else
        json_response( { bank_account: ["incorrect bank account: '#{params[:bank_account]}' "]} , 400)
      end
    end
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

  # no longer needed
  def source_types_include?(source_type)
    Fiat::FUND_TYPE.include?(source_type)
  end

  def get_bankaccount(bank_account, params=nil)
    b_account = nil
    return nil unless CONFIG[:fiat_accounts]
    CONFIG[:fiat_accounts].to_hash.each do |currency, accounts|
      return nil unless accounts
      accounts.each { |k, v| break if b_account ;v.each do |account|
        if account["bsb"] == bank_account.split("-")[0] && account["account_number"] == bank_account.split("-")[1]
          b_account = account.select {|key, _| not CONFIG[:fiat][:bank_accounts_filter].include? key}
          params[:currency] ||= currency if params
          break
        end
      end }
    end
    b_account
  end

  def transfer_params
    # whitelist params
    params.permit(:source_id, :source_name, :source_code, :transfer_type, :amount, :customer_code, :currency, :result, :description, :sender_info)
  end

  def search_params
    # whitelist params
    params.permit(:source_id, :status, :result, :created_at, :archive_before, :per_page, :page_num)
  end

  def set_transfer
    @transfer = TransferIn.find(params[:id])
  end
end
