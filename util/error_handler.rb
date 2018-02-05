require_relative '../config/fiat_config.rb'

class ErrorHandler
  def self.error_info e
    "#{e.inspect}, debug_info: #{e.backtrace[0..2]}"
  end
end

class FiatServiceError < StandardError
  def code; "ef000"; end
end

class InvalidCommand < FiatServiceError
  def code; "ef100"; end
end

class IlleagalRequestError < FiatServiceError
  def code; "ef100"; end
end

class InvalidArgumentError < FiatServiceError
  def code; "ef101"; end
end

class ConnectionRefusedError < FiatServiceError
  def code; "ef102"; end
end

class CodecalRPCError < FiatServiceError
  def code; "ef103"; end
end
