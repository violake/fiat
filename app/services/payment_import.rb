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
    #    payments : Tempfile
    #  [return]
    #    status -- true/false if imported successfully or not
    #    result -- a hash : {imported: 0, ignored: 0, error: 0} when status true; error messages when status false
    #  [used attribute:]
    #  @csv_str : Tempfile read string
    ##
    def importPayments(params)
      begin
        @csv_path = params[:payments].tempfile
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

    private

    def readcsv
      @payments = []
      CSV.foreach(@csv_path,
        :quote_char=>'"',
        :col_sep =>",", 
        :headers => true, 
        :header_converters => :symbol ) do |row|
        @column_name ||= row.headers
        @payments.push(row.to_h) 
      end
    end


    # save to payments table
    def save
      @result = {imported: 0, ignored: 0, error: 0}
      @payments.each do |payment|
        payclass = Fiat.const_get(payment[:payment_type])
        raise "payment type unknown ! \"#{payment[:payment_type]}\" " unless payclass
        pay = payclass.find_or_initialize_by(source_id: payment[:source_id], source_code: payment[:source_code])
        if(pay.valid_to_import?)
          pay.set_values(payment)
          pay.save
          @result[:imported] += 1
          @result[:error] += 1 if pay.result == :error
        else
          @result[:ignored] += 1
        end
      end
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
