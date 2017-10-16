class Payment < ApplicationRecord
  has_paper_trail

  STATUS = [:new, :sent, :archived]
  RESULT = [:unreconciled, :reconciled, :error]

  extend Enumerize

  enumerize :status, in: STATUS, scope: true
  enumerize :result, in: RESULT, scope: true

  validates_presence_of :source_id, :source_name, :source_code, :payment_type, :amount, :currency
  validates_uniqueness_of :source_id, :scope => :source_code
  validates :txid, uniqueness: true, allow_nil: true

  @@local = nil

  def self.set_timezone(timezone)
    regex = /^[+\-](0\d|1[0-2]):([0-5]\d)$/
    return timezone unless regex.match(timezone)
    zone = timezone.split(":")
    @@local = Time.zone
    Time.zone = (zone[0] + "." + ((zone[1].to_f)/60*100).to_i.to_s).to_f.hours
  end

  def self.timezone_reset
    Time.zone = @@local
  end

  def self.timezone_changed?
    @@local ? true : false
  end

  def self.get_daily_sum(start_date, end_date, bank_account = nil)
    c = self.connection
    source_code_str = bank_account ? "and source_code like '%#{bank_account[0..5]}%' and source_code like '%#{bank_account[6..-1]}%'" : ""
    results = c.execute("select a.source_code, a.amount, IFNULL(b.amount,0) as reconciled_amount, a.date, a.currency from " \
                        "(select source_code, FORMAT(sum(IFNULL(amount, 0)), 2) as amount, DATE(created_at) as date, currency from payments " \
                        "where DATE(created_at) between #{start_date} and #{end_date} " \
                        "#{source_code_str} " \
                        "group by source_code, DATE(created_at) ) a left outer join " \
                        "(select source_code, FORMAT(sum(IFNULL(amount, 0)), 2) as amount, DATE(created_at) as date, currency from payments " \
                        "where DATE(created_at) between #{start_date} and #{end_date} " \
                        "#{source_code_str} " \
                        "and result = 'reconciled' " \
                        "group by source_code, DATE(created_at) ) b " \
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

  def archive!
    if self.status != :new
      self.status = :archived
      self.save
    end
  end

  def convertTimeZone(timestr)
    return Time.zone.parse(timestr).to_s
  end

  def valid_to_import?
    return true if (self.status == nil || self.result == nil) ||
                   (self.status == :new && (self.result == :unreconciled || self.result == :error) ) ||
                   (self.status == :sent && self.result == :error)
    return false
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
                    txid
                    sender_info
                    error_info
                    status
                    result}

    CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << attributes

      all.each do |payment|
        csv << attributes.map{ |attr| payment.send(attr) }
      end
    end
  end

end