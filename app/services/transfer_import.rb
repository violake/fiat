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
        raise "no source file" unless file
        Transfer.set_timezone(params[:timezone])
        @csv_path = File.expand_path(file)
        handle_params(params)
        fiat_process
        @result
      rescue Exception=>e
        puts e.message
        puts e.backtrace.inspect
      ensure
        Transfer.timezone_reset if Transfer.timezone_changed?
      end
    end
    
    private

  end

end