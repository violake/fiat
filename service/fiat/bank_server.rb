require 'rubygems'
require 'yaml'
require 'bigdecimal'
require 'codecal'
require 'active_record'
require 'enumerize'

require 'paper_trail'
require './app/models/application_record'
Dir['./app/models/*.rb'].each {|file| require file }
Dir['./app/models/payments/*.rb'].each {|file| require file }
require_relative '../../util/error_handler'
require_relative '../../db/data_accessor.rb'

class BankServer
  def initialize(fiat_config, logger)
    @fiat_config = fiat_config
    @logger = logger
  end

  #
  #==== Get unique Customer Deposit Code for account
  #
  # params:
  #   account_id : string  - account id of user
  #
  # return : string  - customer deposit code
  #
  def getcustomercode(account_id)
    result = Codecal.simple_code_generate(account_id)
    raise CodecalRPCError, result[:error] if result[:error]
    result[:customer_code]   #Customer Code
  end
 

  #
  #==== Validate Customer Deposit Code for account
  #
  # params :
  #   Customer Deposit Code : string(16)  - user account deposit code
  #   account_id            : Interger    - user account id
  #
  # return : hash
  # {
  #   :isvalid => <isvalid>  : boolean  - true if this 'customer deposit code' is valid
  #   ismine => <ismine>     : boolean  - true if this 'customer deposit code' is mine
  # }
  #
  def validatecustomercode(customer_code, account_id)
    valid = Codecal.validate_simple_code(customer_code)
    check_result = getcustomercode(account_id) if valid
    {isvalid: valid, ismine: check_result ? check_result==customer_code : false}
  end

  #==== deposit rabbitmq command
  #
  # params :
  #   payment_id     : string  - payment id sent to acx for autodeposit
  #   deposit_remote : Hash    - deposit data from acx
  #
  # return : hash
  #   success : boolean
  #
  def autodeposit(params)
    payment_id = params["payment_id"]
    response = {log: true, payment_id: payment_id}
    unless params["error"]
      deposit_remote = params["deposit"]
      response[:deposit_id] = deposit_remote["deposit_id"]
      payment = Payment.find(payment_id)
      deposit = Deposit.find_or_initialize_by(id: deposit_remote["deposit_id"])
      if (!deposit.aasm_state || deposit.aasm_state != deposit_remote["aasm_state"]) && (!deposit.done_at || deposit.done_at < deposit_remote["updated_at"])
        deposit.set_values(deposit_remote)
        deposit.save
        deposit = Deposit.find(deposit.id)
        payment.deposit(deposit, deposit_remote["error"])
        response[:success] = true
      else
        response[:success] = false
        response[:error] = "deposit already done"
      end
    else
      payment = Payment.find(payment_id)
      payment.error_info = params["error"]
      payment.result = :error
      payment.save
      response[:success] = true
    end
    response
  end

  def resend
    Payment.with_status(:sent).with_result(:unreconciled).where('send_times >= ?', @fiat_config[:resend_times]).each do |payment|
      payment.result = :error
      payment.error_info = "Resend times over limitation #{@fiat_config[:resend_times]}"
      payment.save
    end
    Payment.with_status(:sent).with_result(:unreconciled).where('updated_at < ? and send_times < ?', Time.now.utc - @fiat_config[:resend_lag].minutes, @fiat_config[:resend_times]).inject(0) do |count, payment|
      response = {"command": "reconcile", "payment": payment}
      AMQPQueue.enqueue(response)
      @logger.debug "resent :#{response}"
      payment.send_times += 1
      payment.save
      count += 1
    end
  end

  def update_send_single_payment(id, params)
    payment = Payment.find(id)
    if payment.mend_error(params)
      send_payments([payment])
    else
      raise "saving payment(#{id}) error: '#{payment.errors.messages}'"
    end
  end

  def send_single_payment(id)
    payment = Payment.find(id)
    send_payments([payment])
  end

  def get_payment(id)
    payment = Payment.find(id)
  end

  def sync_bank_accounts
    response = {"command"=>"syncbankaccounts", "key"=>"bank"}
    AMQPQueue.enqueue(response)
    @logger.info "*** bank_server send sync bank accounts ***"
  end

  def refreshbankaccounts(params)
    hash = YAML.load_file("./config/fund_source.yml")

    params.each do |currency, accounts|
      if hash && hash["fiat_accounts"] && hash["fiat_accounts"].has_key?(currency)
        hash["fiat_accounts"][currency] ||= {}
        hash["fiat_accounts"][currency]["bank_accounts"] ||= []
        accounts.each do |account|
          hash["fiat_accounts"][currency]["bank_accounts"].push(account) if ! hash["fiat_accounts"][currency]["bank_accounts"].include?(account)
        end
      else
        hash ||= {}
        hash["fiat_accounts"] ||= {}
        hash["fiat_accounts"][currency] ||= {}
        hash["fiat_accounts"][currency]["bank_accounts"] ||= []
        accounts.each {|account| hash["fiat_accounts"][currency]["bank_accounts"].push(account) }
      end
    end

    hash["fund_timestamp"] = Time.now

    File.write("./config/fund_source.yml", hash.to_yaml)
    return response = {log: true, result: "bank accounts refreshed"}
  end

  private 

  def send_payments(payments)
    payments.each do |payment|
      response = {"command": "reconcile", "payment": payment}
      AMQPQueue.enqueue(response)
      @logger.debug "sent :#{response}"
      unless payment.status_sent?
        payment.status = :sent
        payment.save
      end
    end
  end

end