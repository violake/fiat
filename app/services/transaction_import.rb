require_relative 'validation'

module Fiat
  
  class TransactionImport
    include Fiat::Validation

    def importPayments(params)
      @csv_path = params[:payments].tempfile
      @source_type = params[:source_type]
      @currency = params[:currency]
      @bank_account = params[:bank_account]
      readcsv
      check
      save
      send_to_acx
    end

    def importPaymentsFile(file, params)
      raise "no source file" unless file
      @csv_path = File.expand_path(file)
      @source_type = params[:source_type]
      @currency = params[:currency]
      @bank_account = params[:bank_account]
      readcsv
      check
      save
      send_to_acx
    end
  
  end

end