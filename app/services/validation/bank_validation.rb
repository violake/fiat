require_relative 'base_validation'
module Fiat
  class BankValidation < BaseValidation

    def self.check_columnname(column_names)
      [:source_id, :source_code, :payment_type, :amount, :currency, :created_at].inject([]) do |missing, column|
        if column_names.include?(column) then missing else missing.push(column) end
      end
    end

    def self.validate(payment)
      valid, errormsg = super
      return valid, errormsg unless valid
      error = ""
      error += datetime_valid(payment[:created_at])
      error += datetime_valid(payment[:updated_at]) if payment[:updated_at]
      return error.size == 0, error
    end

  end
end