require 'codecal'
require_relative '../../../config/fiat_config'


module Fiat

  module TransferIns

    class Bank < TransferIn
      extend Fiat::Convert

      def self.import(transfers)
        result = {imported: 0, ignored: 0, error: 0}
        TransferIn.transaction do
          transfers.each do |transfer|
            transfer_in = self.find_or_initialize_by(source_id: transfer[:source_id], source_code: transfer[:source_code])
            if(transfer_in.valid_to_import?)
              transfer_in.set_values(transfer)
              transfer_in.save
              result[:imported] += 1
              result[:error] += 1 if transfer_in.result == :error
            else
              result[:ignored] += 1
            end
          end
        end
        result
      end

      def set_values(bank)
        self.source_id ||= bank[:source_id]
        self.source_name = bank[:source_name]
        self.source_code = bank[:source_code]
        self.country = bank[:country]
        self.transfer_type = bank[:transfer_type]
        self.amount = bank[:amount]
        self.currency = bank[:currency]
        self.available = bank[:available] ? bank[:available] : "true"
        self.created_at = Bank.convertTimeZone(bank[:created_at])
        self.updated_at = bank[:updated_at] ? Bank.convertTimeZone(bank[:updated_at]) : nil
        self.description = bank[:description]
        self.sender_info = bank[:sender_info]
        self.status = :new
        self.customer_code = capture_customer_code(bank[:description])
        self.customer_code == nil ? self.result = :error : self.result = :unreconciled
        self.error_info = nil
        self.error_info = "missing customer deposit code" if self.result == :error
        self.source_type = bank[:source_type]
        filter_transition_deposit_id
      end

      def filter_transition_deposit_id
        @@deposit_ids = nil unless defined? @@deposit_ids
        path = Rails.root.join('config', "transition_deposits.yml")
        @@deposit_ids ||= YAML.load_file(File.new(path))["deposit_ids"] if File.exist?(path)

        if @@deposit_ids.is_a?(Array) && self.customer_code && (@@deposit_ids.include?(self.customer_code))
          self.error_info = "This code could be a deposit id. It needs to be manually handled."
          self.result = :error
        end
      end

      private

      def capture_customer_code(description)
        customer_code = nil
        description.scan(%r[#{FiatConfig.new[:fiat][:customer_code_regex]}]).each do |code|
          if Codecal.validate_masked_code(FiatConfig.new[:fiat][:customer_code_mask], code.downcase)
            customer_code = code.downcase
            return customer_code
          end
        end
        customer_code
      end
    end

  end

end