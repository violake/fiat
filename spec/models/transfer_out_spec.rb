require 'rails_helper'

RSpec.describe TransferOut, type: :model do
  let(:transfer_out) { create(:transfer_out) }

  it { should validate_presence_of(:source_id) }
  it { should validate_presence_of(:source_name) }
  it { should validate_presence_of(:source_code) }
  it { should validate_presence_of(:transfer_type) }
  it { should validate_presence_of(:amount) }
  it { should validate_presence_of(:currency) }
  it { should validate_uniqueness_of(:source_id).scoped_to(:source_code)  }
  it { should validate_uniqueness_of(:txid) }
  
end