class TransferOut < ApplicationRecord
 
  STATUS = [:new, :sent, :archived]
  RESULT = [:unreconciled, :reconciled, :error]

  extend Enumerize
  
  enumerize :status, in: STATUS, scope: true, predicates: { prefix: true }
  enumerize :result, in: RESULT, scope: true, predicates: { prefix: true }

  validates_presence_of :source_id, :source_name, :source_code, :transfer_type, :amount, :currency
  validates_uniqueness_of :source_id, :scope => :source_code
  validates :txid, uniqueness: true, allow_nil: true

  def valid_to_import?
    return true if (self.status == nil || self.result == nil) ||
                   (self.status == :new && (self.result == :unreconciled || self.result == :error) ) ||
                   (self.status == :sent && self.result == :error)
    return false
  end

  def withdraw_reconcile(withdraw_remote, withdraw, response)
    errormsg = check_withdraw(withdraw_remote)
    if errormsg
      response[:success] = false
      withdraw.error_info = errormsg
      withdraw.save
      response[:error] = errormsg
    else
      reconcile! if can_reconcile?
      response[:success] = true
    end
  end

  def self.to_csv
    attributes = %w{id
                    source_name
                    source_code
                    source_type
                    country
                    email
                    customer_code
                    transfer_type
                    withdraw_ids
                    lodged_amount
                    amount
                    error_info
                    currency
                    txid
                    description
                    status
                    result
                    created_at
                    updated_at
                    matched_at
                    }

    CSV.generate(headers: true, force_quotes: true) do |csv|
      csv << attributes

      all.each do |transfer|
        csv << attributes.map{ |attr| transfer.send(attr) }
      end
    end
  end

  def withdraws
    Withdraw.where("id in (#{withdraw_ids})").each
  end

  private

  def sum_up_withdraws(column)
    self.withdraws.inject(0) {|sum, withdraw| sum += withdraw.send(column)}
  end

  def can_reconcile?
    return false unless self.result == :unreconciled 
    return false unless self.withdraw_ids            
    return false unless self.withdraw_ids.split(",").size == self.withdraws.size
    return true
  end

  def reconcile!
    self.lodged_amount = sum_up_withdraws("sum")
    self.fee = sum_up_withdraws("fee")
    withdraw_amount = sum_up_withdraws("amount")
    if self.amount == withdraw_amount
      self.result = :reconciled
    else
      self.error_info = "Amount not even: [Bank transfer-out: #{self.amount}, Withdraw Amount: #{withdraw_amount}]"
      self.result = :error
    end
    self.save
  end

  def check_withdraw(withdraw_remote)
    return "missing customer code or customer email" unless withdraw_remote[:customer_code] || withdraw_remote[:email] || withdraw_remote[:txid]
    if self.customer_code == nil && self.email == nil
      self.customer_code = withdraw_remote[:customer_code]
      self.email = withdraw_remote[:email]
      self.save
      nil
    else
      return "customer code not match: [transfer-out: '#{self.customer_code}', withdraw: '#{withdraw_remote[:customer_code]}']" if self.customer_code != withdraw_remote[:customer_code]
      return "customer email not match: [transfer-out: '#{self.email}', withdraw: '#{withdraw_remote[:email]}']" if self.email != withdraw_remote[:email]
      return "txid not match: [transfer-out: '#{self.txid}', withdraw: '#{withdraw_remote[:txid]}']" if self.txid != withdraw_remote[:txid]
    end
  end

end
