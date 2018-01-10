require_relative 'westpac_validation'
module Fiat

  module TransferIns

    class BeyondValidation < WestpacValidation

      def self.check_columnname(column_names)
        [:entered_date, :transaction_description, :amount].inject([]) do |missing, column|
          if column_names.include?(column) then missing else missing.push(column) end
        end
      end

      def self.filter(transfers)
        self.validate_by_sum(self.rename_to_westpac(self.filter_positive_amount(transfers)))
      end

      private
      

      def self.filter_positive_amount(transfers)
        transfers.inject([]) do |filtered_transfers, transfer|
          filtered_transfers.push(transfer) if transfer[:amount].to_i > 0
          filtered_transfers
        end
      end

      def self.rename_to_westpac(transfers)
        maps = {bank_account: :bank_account, entered_date: :date, transaction_description: :narrative, amount: :credit_amount, currency: :currency, source_type: :source_type}
        transfers.map! do |transfer|
          transfer = transfer.map {|k,v| if maps.has_key?(k) then [maps[k],v] else [k,v] end}.to_h
        end
      end
      
    end

  end

end