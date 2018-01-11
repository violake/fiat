require 'rails_helper'
require './app/services/transaction_import.rb'
require './app/services/transfer_out_import'

RSpec.describe Fiat::TransferOutImport do

  before(:all) { @to = Fiat::TransferOutImport.new }

  describe 'import westpac statements' do
    
    it 'return correct result when import normal westpac statement csv' do
      params = {timezone: "+08:00", bank_account: "033152468666", source_type: "westpac", currency: "aud"}
      file = File.new(Rails.root.join("spec/factories/transfer_outs_normal.csv"))
      response = @to.importTransferOutFile(file, params)

      expect(response[:imported]).to eq(6)
      expect(response[:ignored]).to eq(0)
      expect(response[:error]).to eq(1)
      expect(response[:sent]).to eq(5)
      expect(response[:filtered]).to eq(5)
    end

  end

end
