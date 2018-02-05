require_relative 'validation'
require './util/timezone'
require 'active_support/inflector'

module Fiat
  
  class TransactionImport
    include Fiat::Validation
    include Fiat::Timezone

    def initialize
      @module = nil
    end

    def transaction_import(params, send_transaction = true)
      if @module
        handle_params(params)
        yield if block_given?
        transaction_import_process(send_transaction)
      end
    end

    private
    
    # params check
    def check_params(params)
      errormsg = [:source_type, :currency, :bank_account].inject([]) do |error, param|
        error.push(param.to_s) unless params[param]
        error
      end
      raise "Missing params: #{errormsg.to_s}" if errormsg.size > 0
    end

    # assigment params
    def handle_params(params)
      check_params(params)
      @source_type = params[:source_type]
      @currency = params[:currency]
      @bank_account = params[:bank_account]
    end

    # process dealing with csv data
    def transaction_import_process(send_transaction)
      readcsv
      check
      save
      send_to_acx if send_transaction
    end

    def readcsv
      @transactions = []
      CSV.foreach(@csv_path,
        :quote_char=>'"',
        :col_sep =>",", 
        :headers => true, 
        :header_converters => :symbol ) do |row|
        @column_names ||= row.headers
        add_hash = {source_type: @source_type}
        add_hash.merge!(currency: @currency) if !row.to_h.has_key?(:currency) && @currency
        add_hash.merge!(bank_account: @bank_account["bsb"] + @bank_account["account_number"]) if !row.to_h.has_key?(:bank_account) && @bank_account
        @transactions.push(row.to_h.merge!(add_hash) )
      end
      @read_size = @transactions.size
      raise "There is no transaction in the csv file" if @read_size == 0
    end

    # save to transactions table
    def save
      @transaction_class = @module.constantize.const_get(@source_type.capitalize)
      raise "source type unknown ! '#{@source_type}' " unless @transaction_class
      @result = @transaction_class.import(@transactions)
      @result[:filtered] = @read_size - @transactions.size
    end

    # send data with customer_code to ACX via rabbitmq server
    def send_to_acx
      @result[:sent] = @transaction_class.with_status(:new).with_result(:unreconciled).inject(0) do |count, transaction|
        response = {"command"=> "reconcile_#{transaction_name}", transaction_name => transaction}
        AMQPQueue.enqueue(response)
        transaction.status = :sent
        transaction.send_times += 1
        transaction.save
        count += 1
      end
    end

    # get transaction name for this process
    def transaction_name
      @module.split("::").last.underscore.singularize
    end
  
  end

end
