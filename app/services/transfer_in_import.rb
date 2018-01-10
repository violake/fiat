require_relative 'validation'
Dir['./app/models/*.rb'].each {|file| require file }
Dir['./app/models/transfer_ins/*.rb'].each {|file| require file }
require './service/amqp_queue'
require './config/fiat_config'
require './app/services/transaction_import'

module Fiat

  class TransferInImport < TransactionImport

    TRANSFERIN_MODULE = "Fiat::TransferIns"
    ## import transfer-ins called by transfer_controller
    #  [params]
    #    transfers    : Tempfile
    #    bank_account: String     -- json string format bank account detail
    #    source_type : String     -- different converter
    #  [return]
    #    status -- true/false if imported successfully or not
    #    result -- a hash : {imported: 0, ignored: 0, error: 0} when status true; error messages when status false
    #  [used attribute:]
    #  @csv_str : Tempfile read string
    ##
    def importTransferIns(params)
      begin
        @module = TRANSFERIN_MODULE
        @csv_path = params[:transfers].tempfile
        set_timezone(params[:timezone])
        transaction_import(params)
        return true, @result
      rescue Exception=>e
        error_msg = e.message.start_with?("Illegal quoting") ?  "Error Type of File: File should be csv" : e.message
        return false, error_msg
      ensure
        timezone_reset if timezone_changed?
      end
    end

    ## import transfers called by commandline 
    #  [params]
    #  file : String -- file name
    #  [return]
    #  nil
    #  [used attribute:]
    #  @csv_str : Tempfile -- read string
    ##
    def importTransferInsFile(file, params)
      begin
        @module = TRANSFERIN_MODULE
        raise "no source file" unless file
        set_timezone(params[:timezone])
        @csv_path = File.expand_path(file)
        transaction_import(params)
        @result
      rescue Exception=>e
        error_msg = e.message.start_with?("Illegal quoting") ?  "Error Type of File: File should be csv" : e.message
        puts error_msg
        puts e.backtrace.inspect
      ensure
        timezone_reset if timezone_changed?
      end
    end


    def force_reconcile(transfer)
      response = {"command": "force_reconcile", "transfer": transfer}
      AMQPQueue.enqueue(response)
      transfer.status = :sent
      transfer.send_times += 1
      transfer.save
    end

  end

end
