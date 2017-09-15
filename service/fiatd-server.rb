Dir[File.dirname(__FILE__) + '/fiat/*.rb'].each {|file| require file }

class FiatdServer

  CONFIG = FiatConfig.new

  def initialize(logger)
    CONFIG[:payment_type].each do |fiat|
      instance_variable_set("@#{fiat}_server", Kernel.const_get("#{fiat.capitalize}Server").new(CONFIG[fiat], logger, fiat))
    end
  end


  CONFIG[:payment_type].each do |fiat|
    define_method fiat do
      instance_variable_get "@#{fiat}_server"
    end
  end

end

