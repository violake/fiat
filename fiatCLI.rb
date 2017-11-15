#!/usr/bin/env ruby
require_relative './config/environment'
require 'thor'
require 'codecal'
require_relative './app/services/payment_import'
require_relative './config/fiat_config'
require_relative './service/fiat-mailer'
require_relative './util/fiatd_logger'
require_relative './service/fiatd-server'

class FiatCLI < Thor
  
  def initialize(args = [], local_options = {}, config = {})
    super(args, local_options, config)
    @fiat_config = FiatConfig.new
    @opts = {
      server: @fiat_config[:fiat_email][:server],
      port: @fiat_config[:fiat_email][:port],
      domain: @fiat_config[:fiat_email][:domain],
      username: @fiat_config[:fiat_email][:username],
      password: @fiat_config[:fiat_email][:password],
      from: @fiat_config[:fiat_email][:from],
      from_alias: @fiat_config[:fiat_email][:from_alias],
      subject: @fiat_config[:fiat_email][:subject],
      starttls: @fiat_config[:fiat_email][:starttls]
      }
  end

  desc "importCSV csv_file_name", "check payments csv file data and import into database then sending to ACX via MQ"
  method_option :timezone, aliases: '-t', type: :string, required: true, desc: "local timezone, eg: '+08:00'"
  method_option :bank_account, aliases: '-a', type: :string, required: true, desc: "please give the bank account if csv doesn't have, eg: '033152-468666'"
  def importCSV(file)
    raise "timezone format error: '#{options[:timezone]}'. eg: [+08:00] " unless /^[+\-](0\d|1[0-2]):([0-5]\d)$/.match(options[:timezone])
    raise "bank account error: '#{options[:bank_account]}' " if !options[:bank_account] || !( /\d{6}-\d{6,8}/.match(options[:bank_account]) )
    params = convert_to_hash(options)
    bank_account = get_bank_account_detail(params[:bank_account], params)
    raise "invalid bank account: '#{params[:bank_account]}' " unless bank_account
    params[:bank_account] = bank_account
    params[:source_type] = bank_account["bank"].split(' ').shift.downcase
    puts Fiat::PaymentImport.new.importPaymentsFile(file, params)
  rescue Exception=>e
    puts "Error: #{e.message}" 
  end 

  desc "exportErrorCSV", "export error payments to csv file or send email with attachment"
  method_option :to_email, aliases: '-e', type: :string, required: false, desc: "email address for whom you need to inform."
  method_option :filename, aliases: '-f', type: :string, required: false, desc: "file name for the csv."
  def exportErrorCSV
    raise "needs at least one option for this command. -e / -f " if options.size == 0
    rows = Payment.with_result(:error).to_csv
    if options[:to_email]
      FiatMailer.send_email(options[:to_email], @opts, rows) 
    elsif options[:filename]
      puts "writing file"
      File.write("#{options[:filename]}_#{DateTime.parse(Time.now.to_s).strftime('%Y%m%d_%H:%M_%Z')}.csv", rows) 
      puts "done"
    else
      puts "error input: #{options}"
    end
  rescue Exception=>e
    puts "Error: #{e.message}"
  end

  desc "updatePayment id", "update error payment for reconciliation"
  method_option :bank_account, aliases: '-a', type: :string, required: false, desc: "account number which the payment was transfered to."
  method_option :customer_code, aliases: '-c', type: :string, required: false, desc: "customer code for the account of a particular customer."
  method_option :description, aliases: '-d', type: :string, required: false, desc: "description for this payment."
  def updatePayment(id)
    raise "needs at least one option for this command. -a / -c " if options.size == 0
    raise "customer code invalid '#{options[:customer_code]}'" if options[:customer_code] && !Codecal.validate_simple_code(options[:customer_code] )
    params = convert_to_hash(options)
    if params[:bank_account]
      bank_account = get_bank_account_detail(params[:bank_account])
      raise "invalid bank account: '#{params[:bank_account]}' " unless bank_account
      params[:bank_account] = bank_account
    end
    
    puts "payment(#{id}) updating..."
    logger = FiatdLogger.new(@fiat_config[:fiat][:log_level])
    bankServer = BankServer.new(@fiat_config["bank"], logger)
    bankServer.update_send_single_payment(id, params)
    puts "payment(#{id}) sent to MQ"
  rescue Exception=>e
    puts "Error: #{e.message}"
  end

  desc "sendPayment id", "send payment to MQ for reconciliation"
  def sendPayment(id)
    puts "payment(#{id}) sending..."
    logger = FiatdLogger.new(@fiat_config[:fiat][:log_level])
    bankServer = BankServer.new(@fiat_config["bank"], logger)
    bankServer.send_single_payment(id)
    puts "payment(#{id}) sent to MQ"
  rescue Exception=>e
    puts "Error: #{e.message}"
  end

  desc "getPayment id", "get payment record"
  def getPayment(id)
    logger = FiatdLogger.new(@fiat_config[:fiat][:log_level])
    logger = FiatdLogger.new(@fiat_config[:fiat][:log_level])
    bankServer = BankServer.new(@fiat_config["bank"], logger)
    puts bankServer.get_payment(id).inspect
  rescue Exception=>e
    puts "Error: #{e.message}"
  end
    
  desc "dailyAmount currency, *params", "show daily amount summary."
  long_desc <<-LONGDESC
    Check account daily payment summary

    description:\n
    currency: short name of currency. eg: aud\n
    params:
    You can optionally specify params.\n
      single date: 20170909  
    or:\n
      from to date: 20170908 20170910\n
    bank account: bsb-account_number 033152-468666\n
      

    Examples:\n
    > $ fiatCLI.rb dailyAmount aud 20170917\n
    > $ fiatCLI.rb dailyAmount aud 20170917 20170918\n
    > $ fiatCLI.rb dailyAmount aud 20170917 20170918 033152-468666
  LONGDESC
  def dailyAmount(currency, *params)
    if params.size == 1
      start_date, end_date = params[0], params[0]
    else
      start_date, end_date = params[0], params[1]
      bank_account = params[2] ? params[2] : nil
    end
    start_date = DateTime.parse(start_date).strftime("%Y%m%d")
    end_date = DateTime.parse(end_date).strftime("%Y%m%d")
    raise "currency not found: '#{currency}'" unless @fiat_config[:fiat_accounts].has_key? currency
    raise "bank account error '#{bank_account}'" if bank_account && ! (/\d{6}-\d{6,8}/.match(bank_account) )
    raise "invalid bank account: '#{bank_account}' " if bank_account && !get_bank_account_detail(bank_account)
    Payment.get_daily_sum(start_date, end_date, currency, bank_account ? bank_account.delete('-') : nil).map.each {|p| puts p.inject([]){|arr, (k,v)| arr.push("#{k}:#{v}")}.join(", ")}
  rescue Exception=>e
    puts "Error: #{e.message}"
  end
  
  private
  def get_bank_account_detail(bank_account, params=nil)
    b_account = nil
    @fiat_config[:fiat_accounts].to_hash.each do |currency, accounts|
      accounts.each { |k, v| break if b_account ;v.each do |account|
        if account["bsb"] == bank_account.split("-")[0] && account["account_number"] == bank_account.split("-")[1]
          b_account = account 
          params[:currency] ||= currency if params
          break
        end
      end }
    end
    b_account
  end

  def convert_to_hash(options)
    options.inject({}) {|hash, (k,v)| hash.merge!({k.to_sym=>v})}
  end

end

FiatCLI.start(ARGV)