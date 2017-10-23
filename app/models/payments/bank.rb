require 'codecal'
module Fiat

  class Bank < Payment
    def self.import(payments)
      result = {imported: 0, ignored: 0, error: 0}
      payments.each do |payment|
        pay = self.find_or_initialize_by(source_id: payment[:source_id], source_code: payment[:source_code])
        if(pay.valid_to_import?)
          pay.set_values(payment)
          pay.save
          result[:imported] += 1
          result[:error] += 1 if pay.result == :error
        else
          result[:ignored] += 1
        end
      end
      result
    end

    def set_values(bank)
      self.source_id ||= bank[:source_id]
      self.source_name = bank[:source_name]
      self.source_code = bank[:source_code]
      self.country = bank[:country]
      self.payment_type = bank[:payment_type]
      self.amount = bank[:amount]
      self.currency = bank[:currency]
      self.available = bank[:available] ? bank[:available] : "true"
      self.created_at = convertTimeZone(bank[:created_at])
      self.updated_at = bank[:updated_at] ? convertTimeZone(bank[:updated_at]) : nil
      self.description = bank[:description]
      self.sender_info = bank[:sender_info]
      self.status = :new
      customer_code = bank[:description].gsub(/\s+/, "").match(/[\d]{16}/) if bank[:description]
      self.customer_code = customer_code && Codecal.validate_bank_customer_code(customer_code[0]) ? customer_code[0] : nil
      self.customer_code == nil ? self.result = :error : self.result = :unreconciled
      self.error_info = nil
      self.error_info = "missing customer deposit code" if self.result == :error
      self.source_type = bank[:source_type]
    end
  end

end