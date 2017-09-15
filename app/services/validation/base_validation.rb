module Fiat
  class BaseValidation
    def self.validate(payment)
      @error = ""
      [:source_id, :source_code, :amount, :currency, :source_name].each do | column |
        @error += "missing #{column.to_s}\n" if payment[column] == nil || payment[column] == ""
      end

      return @error.size == 0 ? true : false, @error
    end
  end
end