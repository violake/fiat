require 'rubygems'
require 'yaml'
require 'bigdecimal'
require 'codecal'
require 'active_record'
require 'enumerize'

Dir['./app/models/*.rb'].each {|file| require file }
Dir['./app/models/payments/*.rb'].each {|file| require file }
require_relative '../../util/error_handler'
require_relative '../../db/data_accessor.rb'

class BankServer
  def initialize(fiat_config, logger, currency)
    @fiat_config = fiat_config
    @logger = logger
    @currency = currency
  end

  #
  #==== Get unique Customer Deposit Code for account
  #
  # params:
  #   account_id : string  - account id of user
  #
  # return : string  - customer deposit code
  #
  def getcustomercode(account_id, currency)
    result = Codecal.bank_customer_code_generate(account_id, currency)
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
  def validatecustomercode(customer_code, account_id, currency)
    valid = Codecal.validate_bank_customer_code(customer_code)
    check_result = getcustomercode(account_id, currency) if valid
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
        deposit.format(deposit_remote)
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
      payment.save
      response[:success] = true
    end
    response
  end


end