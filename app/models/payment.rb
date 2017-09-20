class Payment < ApplicationRecord

  STATUS = [:new, :sent, :archived]
  RESULT = [:unreconciled, :reconciled, :error]

  extend Enumerize

  enumerize :status, in: STATUS, scope: true
  enumerize :result, in: RESULT, scope: true

  validates_presence_of :source_id, :source_name, :source_code, :payment_type, :amount, :currency
  validates_uniqueness_of :source_id, :scope => :source_code

  def deposit(deposit, error)
    self.deposit_id = deposit.id
    self.result = "reconciled" if deposit.aasm_state == "accepted"
    self.matched_at = deposit.updated_at
    self.error_info = error
    self.save
  end

  def self.to_csv
    attributes = %w{source_id
                    source_name
                    source_code
                    country
                    payment_type
                    amount
                    currency
                    available
                    created_at
                    updated_at
                    description
                    sender_info}

    CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << attributes

      all.each do |payment|
        csv << attributes.map{ |attr| payment.send(attr) }
      end
    end
  end

end