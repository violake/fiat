require_relative 'base_validation'
module Fiat
  class WestpacValidation < BaseValidation

    def self.check_columnname(column_names)
      [:bank_account, :date, :narrative, :debit_amount, :credit_amount, :categories, :serial].inject([]) do |missing, column|
        if column_names.include?(column) then missing else missing.push(column) end
      end
    end

    def self.filter(payments)
      self.validate_by_sum(self.filter_white_list(payments))
    end

    def self.validate(payment)
      @@bank_accounts ||= {}
      valid, errormsg = super
      return valid, errormsg unless valid
      error = ""
      error = "currency not set. " unless payment[:currency]
      error += "bank account not valid: '#{payment[:bank_account]}'" unless %r[#{FiatConfig.new[:westpac][:bank_account_regex]}].match(payment[:bank_account])

      if @@bank_accounts.include? (payment[:bank_account])
        payment[:bank_account] = @@bank_accounts[payment[:bank_account]]
      else
        bank_account = nil
        FiatConfig.new[:fiat_accounts].to_hash.each do |currency, accounts|
          accounts.each { |k, v| break if bank_account ;v.each do |account|
            if account["bsb"] == payment[:bank_account][0..5] && account["account_number"] == payment[:bank_account][6..-1]
              bank_account = account.select {|key, _| not self.private_attrs.include? key}
              break
            end
          end }
        end
        raise "invalid bank account: '#{payment[:bank_account]}' " unless bank_account
        @@bank_accounts.merge!({payment[:bank_account]=>bank_account})
        payment[:bank_account] = bank_account
      end

      error += datetime_valid(payment[:date])
      return error.size == 0, error
    end

    def self.validate_by_sum(payments)
      # sort by date
      payments.sort_by!{|k| Time.parse(k[:date])}
      # group by accounts
      a = payments.group_by { |p| p[:bank_account]}
      # group by accounts and date (format to UTC)
      ps = a.inject({}) {|hash, (k,v)| hash.merge!({k=>v.group_by{|k| DateTime.parse(Time.zone.parse(k[:date]).utc.to_s).strftime("%Y%m%d")}})}
      ps_sums = ps.deep_dup
      # calculate daily sum of payments just read in
      ps_sums.each do |_, date|
        date.each do |k, v|
          date[k] = v.inject(0) { |sum, h| sum += BigDecimal.new(h[:credit_amount]) }
        end
      end
      # get daily sum of database according to accounts and currency
      sums = ps_sums.inject({}) do |sum, (account, date)|
        sum.merge!({ account=>Payment.get_daily_sum(DateTime.parse(Time.zone.parse(date.first[0]).to_s).strftime("%Y%m%d"), DateTime.parse(Time.zone.parse(date.to_a.last[0]).to_s).strftime("%Y%m%d"),payments.first[:currency], account) })
      end
      # convert data structure to be the same as ps_sums
      sums.each {|account, date| sums[account] = date.map {|d| d = {DateTime.parse(d[:date]).strftime("%Y%m%d")=>d[:daily_amount]}  } }
      sums.map {|k, v| sums[k] = v.inject([]) {|hash, a| hash += (a.to_a)}.to_h}
      # filter data that daily sum <= it in database
      ps_sums.each do |account, date|
        date.each do |day, sum|
          if sums[account][day] && sum <= sums[account][day]
            #ps[account].delete(day) # delete return beneath if one day filter this kind of data only
            return "daily sum shows no update: '#{sum}'' for #{ps[account][day][0][:date]} while sum in database is '#{sums[account][day]}'"
          end
        end
      end
      # check data that daily sum > it in database and import additional data if fully matched
      ps.map do |account,date|
        date.map do |day, westpacs|
          daily = Westpac.get_sum_by_ids(westpacs)
          if sums[account][day] && daily[:daily_sum] == sums[account][day]
            ps[account][day].delete_if do |westpac|
              daily[:daily_ids].include?(Westpac.generate_id(westpac).to_s)
            end
          elsif !sums[account][day]
          else
            return "daily payment not match: #{ps[account][day][0][:date]}"
          end
        end
      end

      # return filtered payments
      payments = []
      ps.each do |account, date|
        date.each do |k, v|
          v.each do |p|
            payments.push(p)
          end
        end
      end
      payments
    end

    private 

    def self.private_attrs
      ["honesty_point", "acceptable_amount"]
    end

    def self.filter_white_list(payments)
      payments.inject([]) do |filtered_payments, payment|
        filtered_payments.push(payment) if payment[:credit_amount].to_i > 0 && FiatConfig.new[:westpac][:import_filter_categories].include?(payment[:categories])
        filtered_payments
      end
    end

  end
end