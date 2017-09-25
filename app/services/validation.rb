Dir[File.dirname(__FILE__) + '/validation/*.rb'].each {|file| require file }

module Fiat
  FUND_TYPE = Dir["app/models/payments/*.rb"].map!{|file| file.split("/").last.split(".").first.capitalize }
  module Validation

    ## check csv lines validation
    #  [params]
    #  nil
    #  [return]
    #  nil
    #  [used attribute:]
    #  @column_name : array(symbol)  -- check necessary column names not missing
    #  @payments    : array(hash)    -- check payment type valid
    ##
    def check
      # column names must not missing
      [:source_id, :source_code, :payment_type, :amount, :currency].each do | column |
        raise "column name missing : [#{column.to_s}]" unless @column_name.include?(column)
      end

      # check validation according to payment type 
      @payments.each_with_index do |payment,index|
        if payment[:payment_type] == nil || payment[:payment_type] == "" || !Fiat::FUND_TYPE.include?(payment[:payment_type])
          raise "payments type error \"#{payment[:payment_type]}\" in line #{index} !!"
        end
        valid, errormsg = Fiat.const_get("#{payment[:payment_type]}Validation").validate(payment)
        raise "payments data error: #{errormsg} in line #{index+2} !!" unless valid
      end
    end
  end
end