module Fiat

  class Bank < Payment
    def format(bank)
      self.source_id ||= bank[:source_id]
      self.source_name = bank[:source_name]
      self.source_code = bank[:source_code]
      self.country = bank[:country]
      self.payment_type = bank[:payment_type]
      self.amount = bank[:amount]
      self.currency = bank[:currency]
      self.available = bank[:available] ? bank[:available] : "true"
      self.created_at = bank[:created_at]
      self.updated_at = bank[:updated_at]
      self.description = bank[:description]
      self.sender_info = bank[:sender_info]
      self.status = :new
      customer_code = bank[:description].gsub(/\s+/, "").match(/[\d]{16}/)
      self.customer_code = customer_code ? customer_code[0] : nil
      self.customer_code == nil ? self.result = :error : self.result = :unreconciled
      self.error_info = "missing customer deposit code" if self.result == :error
    end
  end

end