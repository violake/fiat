require_relative 'validation'
require './service/amqp_queue'
require './config/fiat_config'
require './app/models/transfer_out'
require './app/services/transaction_import'

module Fiat
  
  class TransferOutImport < TransactionImport

    TRANSFER_MODULE = "Fiat::TransferOuts"

    ## import transfer-out called by commandline 
    #  [params]
    #  file : String -- file name
    #  [return]
    #  nil
    #  [used attribute:]
    #  @csv_str : Tempfile -- read string
    ##
    def importTransferOutsFile(file, params)
      begin
        @module = TRANSFER_MODULE
        raise "no source file" unless file
        set_timezone(params[:timezone])
        @csv_path = File.expand_path(file)
        transaction_import(params)
        @result
      rescue CSV::MalformedCSVError=>e
        error_msg = e.message.start_with?("Illegal quoting") ?  "File should be csv" : e.message
        raise "Import failed - Error Type of File: #{error_msg}"
      ensure
        timezone_reset
      end
    end
    
    private

  end

end