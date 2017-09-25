class Payment < ApplicationRecord

  STATUS = [:new, :sent, :archived]
  RESULT = [:unreconciled, :reconciled, :error]

  extend Enumerize

  enumerize :status, in: STATUS, scope: true
  enumerize :result, in: RESULT, scope: true

  validates_presence_of :source_id, :source_name, :source_code, :payment_type, :amount, :currency
  validates_uniqueness_of :source_id, :scope => :source_code

  def self.set_timezone(timezone)
    regex = /^[+\-](0\d|1[0-2]):([0-5]\d)$/
    return timestr unless regex.match(timezone)
    zone = timezone.split(":")
    @@local = Time.zone
    Time.zone = (zone[0] + "." + ((zone[1].to_f)/60*100).to_i.to_s).to_f.hours
  end

  def self.timezone_reset
    Time.zone = @@local
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