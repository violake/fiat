require './util/convert'

module Fiat

  module TransferOuts
    
    class Westpac < TransferOut
      extend Fiat::Convert

      #:bank_account, :date, :narrative, :debit_amount, :credit_amount, :categories, :serial]


      def self.import(transfers)
        result = {imported: 0, ignored: 0, error: 0}
        TransferOut.transaction do
          transfers.each do |transfer|
            transfer_out = self.find_or_initialize_by(source_id: transfer[:source_id], source_code: transfer[:source_code])
            if(transfer_out.valid_to_import?)
              transfer_out.set_values(transfer)
              transfer_out.save
              result[:imported] += 1
              result[:error] += 1 if transfer_out.result == :error
            else
              result[:ignored] += 1
            end
          end
        end
        result
      end

      def set_values(westpac)
        self.source_id ||= Westpac.generate_id(westpac)
        self.source_name = "Wespac Statement"
        self.source_code = westpac[:bank_account].to_json
        self.country = "Australia"
        self.transfer_type = "Bank"
        self.amount = westpac[:debit_amount]
        self.currency = westpac[:currency]
        self.created_at = Westpac.convertTimeZone(westpac[:date])
        self.description = westpac[:narrative]
        self.status = :new
        self.customer_code = capture_withdraw_ids(westpac[:narrative])
        self.customer_code == nil ? self.result = :error : self.result = :unreconciled
        self.error_info = nil
        self.error_info = "missing withdraw id" if self.result == :error
        self.source_type = westpac[:source_type]
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
