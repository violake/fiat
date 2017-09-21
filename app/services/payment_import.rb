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
    def importPayments(payments, timezone)
      begin
        @csv_str = payments.read
        Payment.set_timezone(timezone)
        read_csv
        format_row
        check
        save
        send_to_acx
        return true, @result
      rescue Exception=>e
        return false, e.message
      ensure
        Payment.timezone_reset
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
    def importPaymentsFile(file, timezone)
      begin
        raise "no source file" unless @file
        csv_path = File.expand_path(@file, File.dirname(__FILE__))
        @csv_str = File.read(csv_path)
        Payment.set_timezone(timezone)
        read_csv
        format_row
        check
        save
        send_to_acx
      rescue Exception=>e
        puts e.message
        puts e.backtrace.inspect
      ensure
        Payment.timezone_reset
      end
    end

    private

    ## read file.read to attribute @data_read
    def read_csv
      payments = @csv_str.split("\n")
      @data_read = Array.new
      payments.each do |line|
        raise "Line format error: Please upload CSV files and wrap quotation mark for each column data" unless line[0] == "\"" && line[-1] == "\""
        line = line[1..-2]
        strip_line = []
        line.split(/","/).each do |v|
          raise "nil data from csv file,it could be error comma ending" unless v
          strip_line.push(v.strip)
        end
        @data_read.push(strip_line)
      end
    end

    #format csv with first line as column name for other lines into @payment array of hash
    def format_row
      @column_name = @data_read.shift.map! {|c| c = c.gsub(/\s+/, "").to_sym}
      @payments = []
      @data_read.each_with_index do |row, index|
        raise "payment line:[#{index+2}]error number of column : #{row.size} while number of column_name : #{@column_name.size}" unless @column_name.size == row.size
        payment = {}
        row.each_with_index do |column, i|
          payment.merge!({@column_name[i]=>column})
        end
        @payments.push(payment)
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
          pay.format(payment)
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
        payment.save
        count += 1
      end
    end
  end
end
