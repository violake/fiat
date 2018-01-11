require_relative 'base_validation'

module Fiat

  class WestpacValidation < BaseValidation

    def self.check_columnname(column_names)
      [:bank_account, :date, :narrative, :debit_amount, :credit_amount, :categories, :serial].inject([]) do |missing, column|
        if column_names.include?(column) then missing else missing.push(column) end
      end
    end

    def self.validate(transfer)
      @@bank_accounts ||= {}
      valid, errormsg = super
      return valid, errormsg unless valid
      error = ""
      error = "currency not set. " unless transfer[:currency]
      error += "bank account not valid: '#{transfer[:bank_account]}'" unless %r[#{FiatConfig.new[:westpac][:bank_account_regex]}].match(transfer[:bank_account])

      if @@bank_accounts.include? (transfer[:bank_account])
        transfer[:bank_account] = @@bank_accounts[transfer[:bank_account]]
      else
        bank_account = nil
        FiatConfig.new[:fiat_accounts].to_hash.each do |currency, accounts|
          accounts.each { 
            |k, v| break if bank_account ;v.each do |account|
              if account["bsb"] == transfer[:bank_account][0..5] && account["account_number"] == transfer[:bank_account][6..-1]
                bank_account = account.select {|key, _| not self.private_attrs.include? key}
                break
              end
            end 
          }
        end
        raise "invalid bank account: '#{transfer[:bank_account]}' " unless bank_account
        @@bank_accounts.merge!({transfer[:bank_account]=>bank_account})
        transfer[:bank_account] = bank_account
      end

      error += datetime_valid(transfer[:date])
      return error.size == 0, error
    end

    private

    def self.private_attrs
      ["honesty_point", "acceptable_amount"]
    end

  end

end