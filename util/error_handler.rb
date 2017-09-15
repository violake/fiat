require_relative '../config/fiat_config.rb'

class ErrorHandler
  def self.error_info e
    "#{e.inspect}, debug_info: #{e.backtrace[0..2]}"
  end
end

class FiatServiceError < StandardError
  def code; "e0000"; end
end

class InvalidCommand < FiatServiceError
  def code; "e1000"; end
end

class InvalidWithdrawAddress < FiatServiceError
  def code; "e1001"; end
end

class HotWithdrawAddress < FiatServiceError
  def code; "e1002"; end
end

class InsufficientBalanceError < FiatServiceError
  def code; "e1003"; end
end

class InvalidArgumentError < FiatServiceError
  def code; "e1004"; end
end

class ConnectionRefusedError < FiatServiceError
  def code; "e1005"; end
end

class CodecalRPCError < FiatServiceError
  def code; "e1007"; end
end

class NotEnoughUnspendError < StandardError
  def code; "e2001"; end
end
