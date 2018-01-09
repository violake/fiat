require_relative 'validation'
require './service/amqp_queue'
require './config/fiat_config'
require './app/models/transfer'

module Fiat
  
  class TransferImport < TransactionImport

    TRANSFER_MODULE = "Fiat::Transfers"

    ## import transfers called by commandline 
    #  [params]
    #  file : String -- file name
    #  [return]
    #  nil
    #  [used attribute:]
    #  @csv_str : Tempfile -- read string
    ##
    def importTransfersFile(file, params)
      begin
        @module = TRANSFER_MODULE
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
    
    private

  end

end