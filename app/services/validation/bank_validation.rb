module Fiat
  class BankValidation < BaseValidation
    def self.validate(payment)
      valid, errormsg = super
      return valid, errormsg unless valid
      error = ""
      error += datetime_valid(payment[:created_at]) if payment[:created_at]
      error += datetime_valid(payment[:updated_at]) if payment[:updated_at]
      return error.size == 0, error
    end

    def self.datetime_valid(date)
      begin
        Time.zone.parse(date)
        return ""
      rescue Exception=>e
        return "[error date] " + date
      end
    end
  end
end