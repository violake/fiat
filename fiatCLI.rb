require_relative './config/environment'
require 'thor'
require_relative './config/fiat_config'
require_relative './app/services/payment_import'


class FiatCLI < Thor
  
  #==== Initalize the class
  #
  # read and parse database.yml on the same directory
  #
  def initialize(args = [], local_options = {}, config = {})
    super(args, local_options, config)
    @fiat_config = FiatConfig.new
    puts @fiat_config[:log_level]
    
  end

  desc "importCSV csv_file_name timezone", "check payments csv file data and import into database then sending to ACX via MQ"
  def importCSV(file, timezone)
    begin
      raise "timezone format error: '#{timezone}'. eg: [+08:00] " if  !timezone || ! (/^[+\-](0\d|1[0-2]):([0-5]\d)$/.match(timezone) )
      puts Fiat::PaymentImport.new.importPaymentsFile(file, timezone)
    rescue Exception=>e
      puts e.message
    end  
  end 

end

FiatCLI.start(ARGV)