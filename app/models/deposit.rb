class Deposit < ApplicationRecord
  validates_presence_of :account_id, :member_id, :currency, :lodged_amount, :aasm_state

  def set_values(deposit_remote)
    self.id ||= deposit_remote["deposit_id"]
    self.account_id = deposit_remote["account_id"]
    self.member_id = deposit_remote["member_id"]
    self.currency = deposit_remote["currency"]
    self.lodged_amount = deposit_remote["lodged_amount"]
    self.amount = deposit_remote["amount"]
    self.fee = deposit_remote["fee"]
    self.fund_uid = deposit_remote["fund_uid"]
    self.fund_extra = deposit_remote["fund_extra"]
    self.txid = deposit_remote["txid"]
    self.state = deposit_remote["state"]
    self.aasm_state = deposit_remote["aasm_state"]
    self.created_at ||= deposit_remote["created_at"]
    self.updated_at = deposit_remote["updated_at"]
    self.done_at = deposit_remote["done_at"]
    self.confirmations = deposit_remote["confirmations"]
    self.type = deposit_remote["type"]
    self.payment_transaction_id = deposit_remote["payment_transaction_id"]
    self.txout = deposit_remote["txout"]
  end
end
