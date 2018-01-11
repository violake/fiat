class TransferOut < ApplicationRecord
 
  STATUS = [:new, :sent, :archived]
  RESULT = [:unreconciled, :reconciled, :error]

  extend Enumerize
  
  enumerize :status, in: STATUS, scope: true, predicates: { prefix: true }
  enumerize :result, in: RESULT, scope: true, predicates: { prefix: true }

  validates_uniqueness_of :source_id, :scope => :source_code
  validates :txid, uniqueness: true, allow_nil: true

  def valid_to_import?
    return true if (self.status == nil || self.result == nil) ||
                   (self.status == :new && (self.result == :unreconciled || self.result == :error) ) ||
                   (self.status == :sent && self.result == :error)
    return false
  end

  def self.to_csv
    attributes = %w{id
                    source_name
                    source_code
                    source_type
                    country
                    transfer_type
                    amount
                    currency
                    withdraw_ids
                    customer_code
                    created_at
                    updated_at
                    matched_at
                    txid
                    description
                    error_info
                    status
                    result}

    CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << attributes

      all.each do |transfer|
        csv << attributes.map{ |attr| transfer.send(attr) }
      end
    end
  end

end