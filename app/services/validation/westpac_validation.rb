module Fiat
  class WestpacValidation < BaseValidation
    def self.check_columnname(column_names)
      [:bank_account, :date, :narrative, :debit_amount, :credit_amount, :categories, :serial].inject([]) do |missing, column|
        if column_names.include?(column) then missing else missing.push(column) end
      end
    end

    def self.filter(payments)
      payments.inject([]) do |filtered_payments, payment|
        filtered_payments.push(payment) if payment[:credit_amount].to_i > 0 && FiatConfig.new[:westpac][:import_filter_categories].include?(payment[:categories])
        filtered_payments
      end
    end

    def self.validate(payment)
      valid, errormsg = super
      return valid, errormsg unless valid
      error = ""
      error = "currency not set" unless payment[:currency]
      error += "bank account not valid: '#{payment[:bank_account]}'" unless %r[#{FiatConfig.new[:westpac][:bank_account_regex]}].match(payment[:bank_account])
      error += datetime_valid(payment[:date])
      return error.size == 0, error
    end
  end
end