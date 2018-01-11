require_relative '../westpac_validation'

module Fiat

  module TransferIns

    class WestpacValidation < Fiat::WestpacValidation

      def self.filter(transfers)
        self.validate_by_sum(self.filter_white_list(transfers))
      end

      def self.validate_by_sum(transfers)
        # sort by date
        transfers.sort_by!{|k| Time.parse(k[:date])}
        # group by accounts
        a = transfers.group_by { |t| t[:bank_account]}
        # group by accounts and date (format to UTC)
        ts = a.inject({}) {|hash, (k,v)| hash.merge!({k=>v.group_by{|k| DateTime.parse(Time.zone.parse(k[:date]).utc.to_s).strftime("%Y%m%d")}})}
        ts_sums = ts.deep_dup
        # calculate daily sum of transfers just read in
        ts_sums.each do |_, date|
          date.each do |k, v|
            date[k] = v.inject(0) { |sum, h| sum += BigDecimal.new(h[:credit_amount]) }
          end
        end
        # get daily sum of database according to accounts and currency
        sums = ts_sums.inject({}) do |sum, (account, date)|
          sum.merge!({ account=>TransferIn.get_daily_sum(DateTime.parse(Time.zone.parse(date.first[0]).to_s).strftime("%Y%m%d"), DateTime.parse(Time.zone.parse(date.to_a.last[0]).to_s).strftime("%Y%m%d"), transfers.first[:currency], account) })
        end
        # convert data structure to be the same as ps_sums
        sums.each {|account, date| sums[account] = date.map {|d| d = {DateTime.parse(d[:date]).strftime("%Y%m%d")=>d[:daily_amount]}  } }
        sums.map {|k, v| sums[k] = v.inject([]) {|hash, a| hash += (a.to_a)}.to_h}
        # filter data that daily sum <= it in database
        ts_sums.each do |account, date|
          date.each do |day, sum|
            if sums[account][day] && sum <= sums[account][day]
              #ts[account].delete(day) # delete return beneath if one day filter this kind of data only
              return "daily sum shows no update: '#{sum}'' for #{ts[account][day][0][:date]} while sum in database is '#{sums[account][day]}'"
            end
          end
        end
        # check data that daily sum > it in database and import additional data if fully matched
        ts.map do |account,date|
          date.map do |day, westpacs|
            daily = Fiat::TransferIns::Westpac.get_sum_by_ids(westpacs)
            if sums[account][day] && daily[:daily_sum] == sums[account][day]
              ts[account][day].delete_if do |westpac|
                daily[:daily_ids].include?(Westpac.generate_id(westpac).to_s)
              end
            elsif !sums[account][day]
            else
              return "daily transfer not match: #{ts[account][day][0][:date]}"
            end
          end
        end

        # return filtered transfers
        transfers = []
        ts.each do |account, date|
          date.each do |k, v|
            v.each do |t|
              transfers.push(t)
            end
          end
        end
        transfers
      end

      private 

      def self.filter_white_list(transfers)
        transfers.inject([]) do |filtered_transfers, transfer|
          filtered_transfers.push(transfer) if transfer[:credit_amount].to_i > 0 && FiatConfig.new[:westpac][:import_transfer_in_categories].include?(transfer[:categories])
          filtered_transfers
        end
      end

    end

  end

end
