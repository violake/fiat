#!/usr/bin/env ruby
require_relative './config/environment'
require 'thor'
require 'codecal'
require_relative './app/services/transfer_in_import'
require_relative './app/services/transfer_out_import'
require_relative './config/fiat_config'
require_relative './service/fiat-mailer'
require_relative './util/fiatd_logger'
require_relative './service/fiatd-server'
require './util/timezone'

class FiatCLI < Thor
  include Fiat::Timezone

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
      starttls: @fiat_config[:fiat_email][:starttls],
      body: @fiat_config[:fiat_email][:body]
      }
  end

  desc "importCSV csv_file_name", "check transfers csv file data and import into database then sending to ACX via MQ"
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
    puts Fiat::TransferInImport.new.importTransferInsFile(file, params)
  rescue Exception=>e
    print_errormsg(e)
  end 

  desc "importTransferOutCSV csv_file_name", "check transfers csv file data and import into database then sending to ACX via MQ"
  method_option :timezone, aliases: '-t', type: :string, required: true, desc: "local timezone, eg: '+08:00'"
  method_option :bank_account, aliases: '-a', type: :string, required: true, desc: "please give the bank account if csv doesn't have, eg: '033152-468666'"
  def importTransferOutCSV(file)
    raise "timezone format error: '#{options[:timezone]}'. eg: [+08:00] " unless /^[+\-](0\d|1[0-2]):([0-5]\d)$/.match(options[:timezone])
    raise "bank account error: '#{options[:bank_account]}' " if !options[:bank_account] || !( /\d{6}-\d{6,8}/.match(options[:bank_account]) )
    params = convert_to_hash(options)
    bank_account = get_bank_account_detail(params[:bank_account], params)
    raise "invalid bank account: '#{params[:bank_account]}' " unless bank_account
    params[:bank_account] = bank_account
    params[:source_type] = bank_account["bank"].split(' ').shift.downcase
    puts Fiat::TransferOutImport.new.importTransferOutsFile(file, params)
  rescue Exception=>e
    print_errormsg(e)
  end

  desc "exportErrorCSV", "export error transfers to csv file or send email with attachment"
  method_option :to_email, aliases: '-e', type: :array, required: false, desc: "email address for whom you need to inform."
  method_option :filename, aliases: '-f', type: :string, required: false, desc: "file name for the csv."
  method_option :body, aliases: '-b', type: :string, required: false, desc: "body for the email."
  def exportErrorCSV
    raise "needs at least one option for this command. -e / -f " if options.size == 0
    rows = TransferIn.with_result(:error)
    puts "export #{rows.size} rows of error data"
    if options[:to_email]
      @opts[:subject] = "Deposit Reconciliation"
      @opts[:filename] = "transfer-in_error"
      FiatMailer.send_email(options[:to_email], options[:body] ? @opts.merge!({body: options[:body]}) : @opts, rows.to_csv) 
    elsif options[:filename]
      puts "writing file"
      File.write("#{options[:filename]}_#{DateTime.parse(Time.now.to_s).strftime('%Y%m%d_%H:%M_%Z')}.csv", rows.to_csv) 
      puts "done"
    else
      puts "error input: #{options}"
    end
  rescue Exception=>e
    print_errormsg(e)
  end

  desc "exportTransferOutDailyReportCSV", "export unreconciled and error transfer-out to csv file or send email with attachment"
  method_option :zone_name, aliases: '-z', type: :string, required: true, desc: "local timezone, eg: '+08:00'"
  method_option :date, aliases: '-d', type: :string, required: true, desc: "local timezone, eg: '+08:00'"
  method_option :to_email, aliases: '-e', type: :array, required: false, desc: "email address for whom you need to inform."
  method_option :filename, aliases: '-f', type: :string, required: false, desc: "file name for the csv."
  method_option :body, aliases: '-b', type: :string, required: false, desc: "body for the email."
  def exportTransferOutDailyReportCSV
    raise "parameters not sufficient -z, -d, -e/-f" if options.size < 3
    date = confert_time_by_zone_name(options[:date], options[:zone_name])
    rows = TransferOut.with_date('updated_at', date)
    puts "#{rows.size} rows data in report"
    if options[:to_email]
      @opts[:subject] = "Withdrawal Reconciliation-#{options[:date]}"
      @opts[:filename] = "transfer-out_report_#{options[:date]}"
      FiatMailer.send_email(options[:to_email], options[:body] ? @opts.merge!({body: options[:body]}) : @opts, rows.to_csv) 
    elsif options[:filename]
      puts "writing file"
      File.write("#{options[:filename]}_#{DateTime.parse(Time.now.to_s).strftime('%Y%m%d_%H:%M_%Z')}.csv", rows.to_csv) 
      puts "done"
    else
      puts "error input: #{options}"
    end
  rescue Exception=>e
    print_errormsg(e)
  end

  desc "updateTransferIn id", "update error transfer for reconciliation"
  method_option :bank_account, aliases: '-a', type: :string, required: false, desc: "account number which the transfer was transfered to."
  method_option :customer_code, aliases: '-c', type: :string, required: false, desc: "customer code for the account of a particular customer."
  method_option :description, aliases: '-d', type: :string, required: false, desc: "description for this transfer."
  def updateTransferIn(id)
    raise "needs at least one option for this command. -a / -c " if options.size == 0
    raise "customer code invalid '#{options[:customer_code]}'" if options[:customer_code] && !Codecal.validate_masked_code(@fiat_config[:fiat][:customer_code_mask], options[:customer_code] )
    params = convert_to_hash(options)
    if params[:bank_account]
      bank_account = get_bank_account_detail(params[:bank_account])
      raise "invalid bank account: '#{params[:bank_account]}' " unless bank_account
      params[:bank_account] = bank_account
    end
    
    puts "transfer-in(#{id}) updating..."
    logger = FiatdLogger.new(@fiat_config[:fiat][:log_level])
    bankServer = BankServer.new(@fiat_config["bank"], logger)
    bankServer.update_send_single_transfer_in(id, params)
    puts "transfer-in(#{id}) sent to MQ"
  rescue Exception=>e
    print_errormsg(e)
  end

  desc "sendTransferIn id", "send transfer to MQ for reconciliation"
  def sendTransferIn(id)
    puts "transfer-in(#{id}) sending..."
    logger = FiatdLogger.new(@fiat_config[:fiat][:log_level])
    bankServer = BankServer.new(@fiat_config["bank"], logger)
    bankServer.send_single_transfer_in(id)
    puts "transfer-in(#{id}) sent to MQ"
  rescue Exception=>e
    print_errormsg(e)
  end

  desc "getTransferIn id", "get transfer record"
  def getTransferIn(id)
    logger = FiatdLogger.new(@fiat_config[:fiat][:log_level])
    logger = FiatdLogger.new(@fiat_config[:fiat][:log_level])
    bankServer = BankServer.new(@fiat_config["bank"], logger)
    puts bankServer.get_transfer_in(id).inspect
  rescue Exception=>e
    print_errormsg(e)
  end
    
  desc "dailyAmount currency, *params", "show daily amount summary."
  long_desc <<-LONGDESC
    Check account daily transfer summary

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
    raise "parameter missing" if params.size == 0
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
    TransferIn.get_daily_sum(start_date, end_date, currency, bank_account ? bank_account.delete('-') : nil).map.each {|p| puts p.inject([]){|arr, (k,v)| arr.push("#{k}:#{v}")}.join(", ")}
  rescue Exception=>e
    print_errormsg(e)
  end
  
  private

  def print_errormsg(e)
    puts "Error: #{e.message}"
    #puts e.backtrace.inspect
  end

  def get_bank_account_detail(bank_account, params=nil)
    b_account = nil
    return nil unless @fiat_config[:fiat_accounts]
    @fiat_config[:fiat_accounts].to_hash.each do |currency, accounts|
      return nil unless accounts
      accounts.each { |k, v| break if b_account ;v.each do |account|
        if account["bsb"] == bank_account.split("-")[0] && account["account_number"] == bank_account.split("-")[1]
          b_account = account.select {|key, _| not @fiat_config[:fiat][:bank_accounts_filter].include? key}
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
