require_relative 'westpac_validation'
module Fiat
  class BeyondValidation < WestpacValidation

    def self.check_columnname(column_names)
      [:entered_date, :transaction_description, :amount].inject([]) do |missing, column|
        if column_names.include?(column) then missing else missing.push(column) end
      end
    end

    def self.filter(payments)
      self.validate_by_sum(self.rename_to_westpac(self.filter_positive_amount(payments)))
    end

    private
    

    def self.filter_positive_amount(payments)
      payments.inject([]) do |filtered_payments, payment|
        filtered_payments.push(payment) if payment[:amount].to_i > 0
        filtered_payments
      end
    end

    def self.rename_to_westpac(payments)
      maps = {bank_account: :bank_account, entered_date: :date, transaction_description: :narrative, amount: :credit_amount, currency: :currency, source_type: :source_type}
      payments.map! do |payment|
        payment = payment.map {|k,v| if maps.has_key?(k) then [maps[k],v] else [k,v] end}.to_h
      end
    end
    
  end
end