require_relative 'validation'
Dir['./app/models/*.rb'].each {|file| require file }
Dir['./app/models/payments/*.rb'].each {|file| require file }
require './service/amqp_queue'
require './config/fiat_config'

module Fiat

  class PaymentImport
    include Fiat::Validation

    ## import payments called by payment_controller
    #  [params]
    #    payments    : Tempfile
    #    bank_account: String     -- json string format bank account detail
    #    source_type : String     -- different converter
    #  [return]
    #    status -- true/false if imported successfully or not
    #    result -- a hash : {imported: 0, ignored: 0, error: 0} when status true; error messages when status false
    #  [used attribute:]
    #  @csv_str : Tempfile read string
    ##
    def importPayments(params)
      begin
        @csv_path = params[:payments].tempfile
        @source_type = params[:source_type]
        @currency = params[:currency]
        Payment.set_timezone(params[:timezone])
        readcsv
        check
        save
        send_to_acx
        return true, @result
      rescue Exception=>e
        return false, e.message
      ensure
        Payment.timezone_reset if Payment.timezone_changed?
      end
    end

    ## import payments called by commandline 
    #  [params]
    #  file : String -- file name
    #  [return]
    #  nil
    #  [used attribute:]
    #  @csv_str : Tempfile -- read string
    ##
    def importPaymentsFile(file, params)
      begin
        raise "no source file" unless file
        @csv_path = File.expand_path(file)
        @source_type = params[:source_type]
        @currency = params[:currency]
        Payment.set_timezone(params[:timezone])
        readcsv
        check
        save
        send_to_acx
        @result
      rescue Exception=>e
        puts e.message
        #puts e.backtrace.inspect
      ensure
        Payment.timezone_reset if Payment.timezone_changed?
      end
    end


    def force_reconcile(payment)
      response = {"command": "force_reconcile", "payment": payment}
      AMQPQueue.enqueue(response)
      payment.status = :sent
      payment.send_times += 1
      payment.save
    end

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
        @payments.push(row.to_h.merge!(add_hash) )
      end
      @read_size = @payments.size
    end

    # save to payments table
    def save
      payclass = Fiat.const_get(@source_type.capitalize)
      raise "payment type unknown ! '#{payment[:payment_type]}' " unless payclass
      @result = payclass.import(@payments)
      @result[:filtered] = @read_size - @payments.size
    end

    # send payment with customer_code to rabbitmq server
    def send_to_acx
      @result[:sent] = Payment.with_status(:new).with_result(:unreconciled).inject(0) do |count, payment|
        response = {"command": "reconcile", "payment": payment}
        AMQPQueue.enqueue(response)
        payment.status = :sent
        payment.send_times += 1
        payment.save
        count += 1
      end
    end
  end
end
