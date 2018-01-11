require_relative '../westpac_validation'

module Fiat

  module TransferOuts

    class WestpacValidation < Fiat::WestpacValidation

      def self.filter(transfers)
        self.filter_white_list(transfers)
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