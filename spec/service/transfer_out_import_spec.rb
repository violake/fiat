require 'rails_helper'

RSpec.describe TransferOutImport do

  before(:all) { @to = Fiat::TransferOutImport.new }

  describe 'import westpac statements' do
    
    it 'return correct result when import normal westpac statement csv' do
      params = {timezone: "+08:00", bank_account: "033152468666", source_type: "westpac"}
      file = File.new(Rails.root.join("spec/factories/transfer_outs_normal.csv"))
      response = @to.importTransferOutFile(file, params)

      expect(response['result']['imported']).to eq(6)
      expect(response['result']['ignored']).to eq(0)
      expect(response['result']['error']).to eq(1)
      expect(response['result']['sent']).to eq(5)
      expect(response['result']['filtered']).to eq(5)
    end

  end

end