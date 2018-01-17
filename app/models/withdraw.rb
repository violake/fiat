class Withdraw < ApplicationRecord

  validates_presence_of :account_id, :member_id, :currency, :sum, :aasm_state

  def set_values(withdraw_remote)
    self.id ||= withdraw_remote["deposit_id"]
    self.sn = withdraw_remote["sn"]
    self.account_id = withdraw_remote["account_id"]
    self.member_id = withdraw_remote["member_id"]
    self.currency = withdraw_remote["currency"]
    self.amount = withdraw_remote["amount"]
    self.fee = withdraw_remote["fee"]
    self.sum = withdraw_remote["sum"]
    self.fund_uid = withdraw_remote["fund_uid"]
    self.fund_extra = withdraw_remote["fund_extra"]
    self.txid = withdraw_remote["txid"]
    self.aasm_state = withdraw_remote["aasm_state"]
    self.created_at ||= withdraw_remote["created_at"]
    self.updated_at = withdraw_remote["updated_at"]
    self.done_at = withdraw_remote["done_at"]
    self.class_name = withdraw_remote["type"]
  end
end