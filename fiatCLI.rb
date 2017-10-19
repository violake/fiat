require_relative './config/environment'
require 'thor'
require_relative './app/services/payment_import'
require_relative './config/fiat_config'


class FiatCLI < Thor
  
  #==== Initalize the class
  #
  # read and parse database.yml on the same directory
  #
  def initialize(args = [], local_options = {}, config = {})
    super(args, local_options, config)
    @fiat_config = FiatConfig.new
  end

  desc "importCSV csv_file_name", "check payments csv file data and import into database then sending to ACX via MQ"
  method_option :timezone, aliases: '-t', type: :string, required: true, desc: "local timezone, eg: '+08:00'"
  method_option :bank_account, aliases: '-a', type: :string, required: true, desc: "please give the bank account if csv doesn't have, eg: '033152-468666'"
  def importCSV(file)
    begin
      raise "timezone format error: '#{options[:timezone]}'. eg: [+08:00] " unless /^[+\-](0\d|1[0-2]):([0-5]\d)$/.match(options[:timezone])
      raise "bank account error: '#{options[:bank_account]}' " if !options[:bank_account] || !( /\d{6}-\d{6,8}/.match(options[:bank_account]) )
      params = options.inject({}) {|hash, (k,v)| hash.merge!({k.to_sym=>v})}
      params[:timezone] ||= "+11:00"
      params[:bank_account] ||= "033152-468666" 
      bank_account = get_bank_account_detail(params[:bank_account], params)
      raise "invalid bank account: '#{params[:bank_account]}' " unless bank_account
      params[:bank_account] = bank_account
      params[:source_type] = bank_account["bank"].delete(' ').downcase
      puts Fiat::PaymentImport.new.importPaymentsFile(file, params)
    rescue Exception=>e
      puts e.message
    end  
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
    Payment.get_daily_sum(start_date, end_date, currency, bank_account.delete('-')).map.each {|p| puts p.inject([]){|arr, (k,v)| arr.push("#{k}:#{v}")}.join(", ")}
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

end

FiatCLI.start(ARGV)