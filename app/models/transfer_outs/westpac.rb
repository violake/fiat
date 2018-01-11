module Fiat

  module TransferOuts
    
    class Westpac < TransferOut
      extend Fiat::Jhash

      #:bank_account, :date, :narrative, :debit_amount, :credit_amount, :categories, :serial]


      def self.import(transfers)
      end

      def set_values(westpac)
        self.source_id ||= self.generate_id(westpac)
        self.source_name = "Wespac Statement"
        self.source_code = westpac[:bank_account].to_json
        self.country = "Australia"
        self.transfer_type = "Bank"
        self.amount = westpac[:debit_amount]
        self.currency = westpac[:currency]
        self.created_at = convertTimeZone(bank[:created_at])
        self.updated_at = bank[:updated_at] ? convertTimeZone(bank[:updated_at]) : nil
        self.description = bank[:description]
        self.sender_info = bank[:sender_info]
        self.status = :new
        self.customer_code = capture_customer_code(bank[:description])
        self.customer_code == nil ? self.result = :error : self.result = :unreconciled
        self.error_info = nil
        self.error_info = "missing customer deposit code" if self.result == :error
        self.source_type = bank[:source_type]
      end

      def self.convert(westpac)
        bank = {}
        bank[:source_id] = self.generate_id(westpac)
        bank[:source_name] = "Wespac Statement"
        bank[:source_code] = westpac[:bank_account].to_json
        bank[:country] = "Australia"
        bank[:transfer_type] = "Bank"
        bank[:amount] = westpac[:credit_amount]
        bank[:currency] = westpac[:currency]
        bank[:created_at] = westpac[:date]
        bank[:description] = westpac[:narrative]
        bank[:source_type] = westpac[:source_type]
        return bank
      end

      def self.generate_id(westpac)
        bank_account = westpac[:bank_account].is_a?(String) ? westpac[:bank_account] : westpac[:bank_account]["bsb"] + westpac[:bank_account]["account_number"]
        self.jhash([bank_account, 
                    westpac[:date],
                    westpac[:credit_amount], 
                    westpac[:narrative],
                    westpac[:categories], 
                    westpac[:serial], 
                    westpac[:currency], 
                    westpac[:source_type]].inject(""){|s, k| s+=k if k; s})
      end

    end

  end

end