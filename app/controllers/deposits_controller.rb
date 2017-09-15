class DepositsController < ApplicationController
  before_action :set_deposit, only: [:show]
  # GET /deposits
  def index
    @deposits = Deposit.all
    json_response(@deposits)
  end

  # GET /deposits/:id
  def show
    json_response(@deposit)
  end


  private

  def deposit_params
    # whitelist params
    params.permit(:account_id, :member_id, :currency, :lodged_amount, :aasm_state)
  end

  def set_deposit
    @deposit = Deposit.find(params[:id])
  end
end
