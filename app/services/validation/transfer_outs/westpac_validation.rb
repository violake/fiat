require_relative '../base_validation'
module Fiat

  module TransferOuts

    class WestpacValidation < BaseValidation

      def self.check_columnname(column_names)
        [:bank_account, :date, :narrative, :debit_amount, :credit_amount, :categories, :serial].inject([]) do |missing, column|
          if column_names.include?(column) then missing else missing.push(column) end
        end
      end

      def self.filter(transfers)
        self.filter_white_list(transfers)
      end

      def self.validate(transfer)
      end

      private

      def self.filter_white_list(transfers)
        transfers.inject([]) do |filtered_transfers, transfer|
          filtered_transfers.push(transfer) if transfer[:debit_amount].to_i > 0 && FiatConfig.new[:westpac][:import_transfer_out_categories].include?(transfer[:categories])
          filtered_transfers
        end
      end

    end

  end

end