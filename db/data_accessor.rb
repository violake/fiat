require 'active_record'
require 'yaml'
require_relative '../config/fiat_config'

fiat_config = FiatConfig.new
db = fiat_config[:fiatd]

ActiveRecord::Base.establish_connection(db)