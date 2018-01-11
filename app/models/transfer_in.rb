class TransferIn < ApplicationRecord
  has_paper_trail

  STATUS = [:new, :sent, :archived]
  RESULT = [:unreconciled, :reconciled, :error]

  extend Enumerize

  enumerize :status, in: STATUS, scope: true, predicates: { prefix: true }
  enumerize :result, in: RESULT, scope: true, predicates: { prefix: true }

  validates_presence_of :source_id, :source_name, :source_code, :transfer_type, :amount, :currency
  validates_uniqueness_of :source_id, :scope => :source_code
  validates :txid, uniqueness: true, allow_nil: true

  def self.get_daily_sum(start_date, end_date, currency, bank_account = nil)
    c = self.connection
    source_code_str = bank_account ? "and source_code like '%#{bank_account[0..5]}%' and source_code like '%#{bank_account[6..-1]}%'" : ""
    results = c.execute("select a.source_code, a.amount, IFNULL(b.amount,0) as reconciled_amount, a.date, a.currency from " \
                        "(select source_code, sum(IFNULL(amount, 0)) as amount, DATE(created_at) as date, currency from transfer_ins " \
                        "where DATE(created_at) between #{start_date} and #{end_date} " \
                        "and currency = '#{currency}'" \
                        "#{source_code_str} " \
                        "group by source_code, currency, DATE(created_at) ) a left outer join " \
                        "(select source_code, sum(IFNULL(amount, 0)) as amount, DATE(created_at) as date, currency from transfer_ins " \
                        "where DATE(created_at) between #{start_date} and #{end_date} " \
                        "and currency = '#{currency}'" \
                        "#{source_code_str} " \
                        "and result = 'reconciled' " \
                        "group by source_code, currency, DATE(created_at) ) b " \
                        "on a.date = b.date")
    results.inject([]) do |daily_sum, result|
      daily_sum.push({bank_account: result[0], daily_amount: result[1], reconciled_amount: result[2], date: result[3].to_s, currency: result[4]})
    end
  end

  def deposit(deposit, error)
    self.deposit_id = deposit.id
    self.result = "reconciled" if deposit.aasm_state == "accepted"
    self.matched_at = deposit.updated_at
    self.error_info = error
    self.save
  end

  def mend_error(mend)
    if self.result_error?
      self.source_code = mend[:bank_account].to_json if mend[:bank_account]
      self.customer_code = mend[:customer_code] if mend[:customer_code]
      self.description += " | amend: " + mend[:description] if mend[:description]
      self.result = :unreconciled
      self.status = :new
      self.error_info = nil
      self.save
    else
      self.errors[:base] << "transfer-in result is not 'error'!"
      return false
    end
  end

  def archive!
    if self.status != :new
      self.status = :archived
      self.save
    end
  end

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
                    deposit_id
                    customer_code
                    available
                    created_at
                    updated_at
                    matched_at
                    txid
                    description
                    sender_info
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