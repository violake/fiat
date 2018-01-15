require 'rubygems'
require 'yaml'
require 'bigdecimal'
require 'codecal'
require 'active_record'
require 'enumerize'

require 'paper_trail'
require './app/models/application_record'
Dir['./app/models/*.rb'].each {|file| require file }
Dir['./app/models/transfer_ins/*.rb'].each {|file| require file }
Dir['./app/models/transfer_outs/*.rb'].each {|file| require file }
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
    result = Codecal.code_generate_with_mask(@fiat_config[:customer_code_mask], account_id)
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
    valid = Codecal.validate_masked_code(@fiat_config[:customer_code_mask], customer_code)
    check_result = getcustomercode(account_id) if valid
    {isvalid: valid, ismine: check_result ? check_result==customer_code : false}
  end

  #==== deposit rabbitmq command
  #
  # params :
  #   transfer_id     : string  - transfer id sent to acx for autodeposit
  #   deposit : Hash    - deposit data from acx
  #
  # return : hash
  #   success : boolean
  #
  def autodeposit(params)
    transfer_id = params["transfer_id"]
    response = {log: true, transfer_id: transfer_id}
    if !params["error"] && params["deposit"]
      pair_deposit_to_transfer_in(params["deposit"], response)
    else
      transfer = TransferIn.find(transfer_id)
      transfer.error_info = params["error"]
      transfer.result = :error
      transfer.save
      response[:success] = true
    end
    response
  end

  #==== deposit rabbitmq command
  #
  # params :
  #   transfer_id     : string  - transfer id sent to acx for autowithdraw
  #   withdraw : Hash    - withdraw data from acx
  #
  # return : hash
  #   success : boolean
  #
  def autowithdraw(params)
    transfer_id = params["transfer_id"]
    response = {log: true, transfer_id: transfer_id}
    if !params["error"] && params["withdraw"]
      pair_withdraw_to_transfer_out(params["withdraw"], response)
    else
      save_error_transfer_out(params, response)
    end
    response
  end

  def resend
    TransferIn.with_status(:sent).with_result(:unreconciled).where('send_times >= ?', @fiat_config[:resend_times]).each do |transfer|
      transfer.result = :error
      transfer.error_info = "Resend times over limitation #{@fiat_config[:resend_times]}"
      transfer.save
    end
    TransferIn.with_status(:sent).with_result(:unreconciled).where('updated_at < ? and send_times < ?', Time.now.utc - @fiat_config[:resend_lag].minutes, @fiat_config[:resend_times]).inject(0) do |count, transfer|
      response = {"command": "reconcile", "transfer": transfer}
      AMQPQueue.enqueue(response)
      @logger.debug "resent :#{response}"
      transfer.send_times += 1
      transfer.save
      count += 1
    end
  end

  def update_send_single_transfer_in(id, params)
    transfer = TransferIn.find(id)
    if transfer.mend_error(params)
      send_transfer([transfer])
    else
      raise "saving transfer-in(#{id}) error: '#{transfer.errors.messages}'"
    end
  end

  def send_single_transfer_in(id)
    transfer = TransferIn.find(id)
    send_transfer([transfer])
  end

  def get_transfer_in(id)
    transfer = TransferIn.find(id)
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

  def pair_deposit_to_transfer_in(deposit_remote, response)
    response[:deposit_id] = deposit_remote["deposit_id"]
    transfer = TransferIn.find(response[:transfer_id])
    deposit = Deposit.find_or_initialize_by(id: deposit_remote["deposit_id"])
    if (!deposit.aasm_state || deposit.aasm_state != deposit_remote["aasm_state"]) && (!deposit.done_at || deposit.done_at < deposit_remote["updated_at"])
      deposit.set_values(deposit_remote)
      if deposit.save
        transfer.deposit(deposit, deposit_remote["error"])
        response[:success] = true
      else
        response[:success] = false
        response[:error] = deposit.errors.messages
      end
    else
      response[:success] = false
      response[:error] = "deposit already done"
    end
  end

  def pair_withdraw_to_transfer_out(withdraw_remote, response)
    response[:withdraw_id] = withdraw_remote["withdraw_id"]
    transfer = TransferOut.find(response[:transfer_id])
    withdraw = Withdraw.find_or_initialize_by(id: withdraw_remote["withdraw_id"])
    if !withdraw.aasm_state && !withdraw.done_at && transfer
      withdraw.set_values(withdraw_remote)
      if withdraw.save
        transfer.withdraw_reconcile(withdraw_remote, withdraw, response)
      else
        response[:success] = false
        response[:error] = withdraw.errors.messages
      end
    else
      response[:success] = false
      response[:error] = "withdraw was already matched"
    end
  end

  def save_error_transfer_out(params, response)
    transfer = TransferOut.find(transfer_id)
    if !transfer.result_reconciled?
      transfer.error_info = params["error"]
      transfer.result = :error
      transfer.save
      response[:success] = true
    else
      response[:success] = false
      response[:error] = "transfer-out was already reconciled"
    end
  end

  def send_transfer(transfers)
    transfers.each do |transfer|
      response = {"command": "reconcile_#{transfer.class.underscore}", "#{transfer.class.underscore}": transfer}
      AMQPQueue.enqueue(response)
      @logger.debug "sent :#{response}"
      unless transfer.status_sent?
        transfer.status = :sent
        transfer.save
      end
    end
  end

end