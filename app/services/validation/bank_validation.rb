module Fiat
  class BankValidation < BaseValidation
    def self.validate(payment)
      valid, errormsg = super
      #puts "bank validation : #{payment[:source_name]}"
      return true&&valid, errormsg
    end
  end
end