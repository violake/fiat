require_relative 'westpac'

module Fiat

  module Payments
    
    class Beyond < Westpac
      
      def self.convert(westpac)
        bank = {}
        bank[:source_id] = self.generate_id(westpac)
        bank[:source_name] = "Beyond Bank Statement"
        bank[:source_code] = westpac[:bank_account].to_json
        bank[:country] = "Australia"
        bank[:payment_type] = "Bank"
        bank[:amount] = westpac[:credit_amount]
        bank[:currency] = westpac[:currency]
        bank[:created_at] = westpac[:date]
        bank[:description] = westpac[:narrative]
        bank[:source_type] = westpac[:source_type]
        return bank
      end

    end

  end
  
end