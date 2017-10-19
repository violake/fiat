require_relative 'bank'
require 'json'

module Fiat
  
  class Westpac < Bank
    def self.import(payments)
      result = {imported: 0, ignored: 0, error: 0, rejected: 0}
      payments.each do |payment|
        bank = self.convert(payment)
        pay = self.find_by(source_id: bank[:source_id], source_type: bank[:source_type])
        if pay
          pay.reject_times += 1
          pay.save
          result[:rejected] += 1
        elsif bank[:description]
          pay = self.new
          pay.set_values(bank)
          pay.save
          result[:imported] += 1
          result[:error] += 1 if pay.result == :error
        else
          result[:ignored] += 1
        end
      end
      result
    end

    #{:bank_account=>"033152468666", :date=>"04/10/2017", :narrative=>"DEPOSIT PEAK INTERNATION        BB",
    # :debit_amount=>nil, :credit_amount=>"5000.00", :categories=>"DEP", :serial=>nil}
    def self.convert(westpac)
      bank = {}
      bank[:source_id] = self.generate_id(westpac)
      bank[:source_name] = "Wespac Statement"
      bank[:source_code] = westpac[:bank_account].to_json
      bank[:country] = "Australia"
      bank[:payment_type] = "Bank"
      bank[:amount] = westpac[:credit_amount]
      bank[:currency] = westpac[:currency]
      bank[:created_at] = westpac[:date]
      bank[:description] = westpac[:narrative]
      bank[:source_type] = westpac[:source_type]
      return bank
    end

    def self.get_sum_by_ids(westpacs)
      daily_ids = []
      daily_sum = westpacs.inject(0) do |sum, westpac|
        westpac = self.find_by(source_id: self.generate_id(westpac))
        if westpac && !daily_ids.include?(westpac.source_id)
          daily_ids.push(westpac.source_id)
          sum += westpac.amount
        else
          sum
        end
      end
      {daily_sum: daily_sum, daily_ids: daily_ids}
    end

    def self.generate_id(westpac)
      bank_account = westpac[:bank_account].is_a?(String) ? westpac[:bank_account] : westpac[:bank_account]["bsb"] + westpac[:bank_account]["account_number"]
      self.jhash([bank_account, 
                  westpac[:date],
                  westpac[:credit_amount], 
                  westpac[:narrative],
                  westpac[:categories], 
                  westpac[:serial], 
                  westpac[:currency], 
                  westpac[:source_type]].inject(""){|s, k| s+=k if k; s})
    end

    private

    def self.jhash(str)
      result = 0
      mul = 1
      max_mod = 2**63 - 1
      str.chars.reverse_each do |c|
          result += mul * c.ord
          result %= max_mod
          mul *= 31
      end
      result
    end

  end
end