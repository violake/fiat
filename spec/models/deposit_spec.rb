require 'rails_helper'

RSpec.describe Deposit, type: :model do
  it { should validate_presence_of(:account_id) }
  it { should validate_presence_of(:member_id) }
  it { should validate_presence_of(:currency) }
  it { should validate_presence_of(:lodged_amount) }
  it { should validate_presence_of(:aasm_state) }

end
