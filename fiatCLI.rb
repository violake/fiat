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
  end

  desc "importCSV csv_file_name --timezone '+08:00' --source_type 'westpac' --currency 'aud'", "check payments csv file data and import into database then sending to ACX via MQ"
  method_option :timezone, aliases: '-t', type: :string, required: true, desc: "local timezone, eg: '+08:00'"
  method_option :account, aliases: '-a', type: :string, desc: "please give the account if csv doesn't have, eg: '033152468666'"
  method_option :currency, aliases: '-c', type: :string, desc: "please give the currency if csv doesn't have, eg: 'aud'"
  def importCSV(file)
    begin
      #raise "--timezone format error: '#{options[:timezone]}'. eg: [+08:00] " if  ! (/^[+\-](0\d|1[0-2]):([0-5]\d)$/.match(options[:timezone]) )
      #raise "--invalid bank account: '#{options[:bank_account]}' " if !options[:bank_account] && ! Fiat::FUND_TYPE.include?(options[:bank_account])
      params = options.inject({}) {|hash, (k,v)| hash.merge!({k.to_sym=>v})}
      params[:timezone] ||= "+08:00"
      params[:bank_account] ||= "1204938740218302"
      params[:source_type] ||= "westpac"
      params[:currency] ||= "aud"
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
    bank account: 12/14 digits\n

    Examples:\n
    > $ fiatCLI.rb dailyAmount aud 20170917\n
    > $ fiatCLI.rb dailyAmount aud 20170917 20170918\n
    > $ fiatCLI.rb dailyAmount aud 20170917 20170918 033152468666
  LONGDESC
  def dailyAmount(currency, *params)
    #raise "bank account invalid" unless %r[#{FiatConfig.new[:westpac][:bank_account_regex]}].match(bank_account)
    if params.size == 1
      start_date, end_date = params[0], params[0]
    else
      start_date, end_date = params[0], params[1]
      bank_account = params[2] ? params[2] : nil
    end
    start_date = DateTime.parse(start_date).strftime("%Y%m%d")
    end_date = DateTime.parse(end_date).strftime("%Y%m%d")
    raise "currency not found: '#{currency}'" unless FiatConfig.new[:fiat_accounts].has_key? currency
    raise "bank account invalid" if bank_account && ! (%r[#{FiatConfig.new[:westpac][:bank_account_regex]}].match(bank_account) )
    Payment.get_daily_sum(start_date, end_date, currency, bank_account).map.each {|p| puts p.inject([]){|arr, (k,v)| arr.push("#{k}:#{v}")}.join(", ")}
  end
  
end

FiatCLI.start(ARGV)