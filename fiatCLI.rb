require_relative './config/environment'
require 'thor'
require_relative './app/services/payment_import'


class FiatCLI < Thor
  
  #==== Initalize the class
  #
  # read and parse database.yml on the same directory
  #
  def initialize(args = [], local_options = {}, config = {})
    super(args, local_options, config)
  end

  desc "importCSV csv_file_name --timezone '+08:00' --source_type 'westpac' --currency 'aud'", "check payments csv file data and import into database then sending to ACX via MQ"
  option :timezone
  option :source_type
  option :currency
  def importCSV(file)
    begin
      #raise "--timezone format error: '#{options[:timezone]}'. eg: [+08:00] " if  ! (/^[+\-](0\d|1[0-2]):([0-5]\d)$/.match(options[:timezone]) )
      #raise "--invalid bank account: '#{options[:bank_account]}' " if !options[:bank_account] && ! Fiat::FUND_TYPE.include?(options[:bank_account])
      params = options.inject({}) {|hash, (k,v)| hash.merge!({k.to_sym=>v})}
      params[:timezone] ||= "+08:00"
      params[:bank_account] ||= "1204938740218302"
      puts Fiat::PaymentImport.new.importPaymentsFile(file, params)
    rescue Exception=>e
      puts e.message
    end  
  end 

end

FiatCLI.start(ARGV)