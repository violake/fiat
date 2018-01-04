require_relative 'validation'
require './service/amqp_queue'
require './config/fiat_config'
require './app/models/transfer'

module Fiat
  
  class TransferImport < TransactionImport

    private

    def readcsv
      @payments = []
      CSV.foreach(@csv_path,
        :quote_char=>'"',
        :col_sep =>",", 
        :headers => true, 
        :header_converters => :symbol ) do |row|
        @column_names ||= row.headers
        add_hash = {source_type: @source_type}
        add_hash.merge!(currency: @currency) if !row.to_h.has_key?(:currency) && @currency
        add_hash.merge!(bank_account: @bank_account["bsb"] + @bank_account["account_number"]) if !row.to_h.has_key?(:bank_account) && @bank_account
        @payments.push(row.to_h.merge!(add_hash) )
      end
      @read_size = @payments.size
      raise "There is no transfer in the csv file" if @read_size == 0
    end

    # save to transfers table
    def save
      payclass = Fiat.const_get(@source_type.capitalize)
      raise "transfer type unknown ! '#{transfer[:transfer_type]}' " unless payclass
      @result = payclass.import(@payments)
      @result[:filtered] = @read_size - @payments.size
    end

    # send transfer with customer_code to rabbitmq server
    def send_to_acx
      @result[:sent] = Transfer.with_status(:new).with_result(:unreconciled).inject(0) do |count, transfer|
        response = {"command": "withdraw_reconcile", "transfer": transfer}
        AMQPQueue.enqueue(response)
        transfer.status = :sent
        transfer.send_times += 1
        transfer.save
        count += 1
      end
    end

  end

end